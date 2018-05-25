//+------------------------------------------------------------------+
//|                                                  My First EA.mq4 |
//|                                     MQL4 tutorial on quivofx.com |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, brigacy"
#property link      ""
#property strict

//--- input parameters
//input int            TakeProfit=50;
//input int            StopLoss=50;
//input double         LotSize=0.1;
input int Risk                = 2;
input int Day_Volatility_Back = 3;
input int Slippage            = 3;
input int MagicNumber         = 7777;

input int StartingHour  	=  9;
input int EndingHour  		=  22;
input int StartingMinute  	=  30;
input int endingMinute  	=  30;

//--- indicator inputs
sinput string        indi = "";                // ------ Indicators -----  
input int            RSI_Period = 14;          // RSI Period
input int            RSI_Level  = 30;          // Above RSI Level
input int            MA_Period  = 20;          // MA Period
input int            MA_Period_Fast  = 12;     // MA Period Fast
input int            MA_Period_Slow  = 16;     // MA Period Slow
//input ENUM_MA_METHOD MA_Method  = MODE_SMA;    // MA Method

//--- global variables
double MyPoint;
int    MySlippage;
double MyVolatility;
double VolatilityHight;
double VolatilityLow;

//--- indicators
double RSI;
double MA;
double MACD[2],fast_MA[3],slow_MA[3];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   MyPoint = MyPoint();
   MySlippage = MySlippage();
   
   //TODO: to be removed
   MyVolatility = MyVolatility();
   MyLotSize();

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   Print("##########OnTick()!!!############");
	int nbOrders = TotalOpenOrders();
	
	if(IsTradingTime())
	{
	   if(IsNewBar())
	   { 
			//Update volatilityl
			MyVolatility = MyVolatility();
			
			if (nbOrders == 0) {
			  
			  // Initialize Indicators
			  InitIndicators();
			
			  // Check Buy Entry
			  if(BuySignal())
				 OpenBuy();
				 
			  // Check Sell Entry
			  else if(SellSignal())
				 OpenSell();  
		   } else {
			   //check trailing stop and taking profit
				CheckOpenOrder();
		   }
	   }
   }else {
	   //close order
		if(nbOrders > 0) {
			CloseOrder();
		}
  }
}

//+------------------------------------------------------------------+
//| Market Logic                                                 |
//+------------------------------------------------------------------+

// Initialize Indicators
void InitIndicators()
{
   // RSI
   RSI = iRSI(_Symbol,PERIOD_CURRENT,RSI_Period,PRICE_CLOSE,1);
   
   // Moving Average
   MA = iMA(_Symbol,PERIOD_CURRENT,MA_Period,0,MODE_SMA,PRICE_CLOSE,1);
      
   for(int i=0;i<2;i++)
     {
      // MACD (0-MODE_MAIN, 1-MODE_SIGNAL) -- MACD day period
      MACD[i]=iMACD(_Symbol,PERIOD_D1,12,26,9,PRICE_CLOSE,i,0);

      // Fast MA -- current period
      fast_MA[i+1]=iMA(_Symbol,PERIOD_CURRENT,MA_Period_Fast,0,MODE_EMA,PRICE_CLOSE,1+i);

      // Slow MA -- current period
      slow_MA[i+1]=iMA(_Symbol,PERIOD_CURRENT,MA_Period_Slow,0,MODE_EMA,PRICE_CLOSE,1+i);
     }
   
}

// Buy Logic
bool BuySignal()
{
   
   // MACD zero line filter
   if(!(MACD[0] > 0 && MACD[1] > 0))return(false);

	// MACD trend filter ( ! MAIN > Signal)
   if(!(MACD[0] > MACD[1]))return(false);

	// Check Signal
   if(fast_MA[1] > slow_MA[1] && fast_MA[2] < slow_MA[2])return(true);
   
   //TODO: Ajouter RSI ???
   //if(RSI <= RSI_Level && Low[1] >= MA)
	//return(true);


   return(false);
   
}

// Sell Logic
bool SellSignal()
{

   // MACD zero line filter
   if(!(MACD[0] < 0 && MACD[1] < 0))return(false);

  // MACD trend filter
   if(!(MACD[0] < MACD[1]))return(false);

  // Check Signal
   if(fast_MA[1] < slow_MA[1] && fast_MA[2] > slow_MA[2])return(true);
   
   //TODO: Ajouter RSI ???
   //if(RSI >= 100-RSI_Level && High[1] <= MA)
   //   return(true);

   
   return(false);
}

//+------------------------------------------------------------------+
//| ORDER OPERATION                                                 |
//+------------------------------------------------------------------+ 
 
// Open Buy Order
void OpenBuy()
{
   
   double lotSize;
   
   lotSize = MyLotSize(); 
   if(lotSize == 0) return ;
  
   int ticket = OrderSend(_Symbol,OP_BUY,lotSize,Ask,MySlippage,0,0,"BUY My EA",MagicNumber, 0, Green);
      
      if(ticket<0)
         PrintError("OrderSend");
                 
   // Modify Buy Order
   UpdateOrder();
}


// Open Sell Order
void OpenSell()
{
   //Open Sell Order
   double lotSize = MyLotSize();
   if(lotSize == 0) return ;
   
   int ticket = OrderSend(_Symbol,OP_SELL,lotSize,Bid,MySlippage,0,0,"SELL My EA",MagicNumber, 0, Red);
      
      if(ticket<0)
         PrintError("OrderSend");
                 
   // Modify Sell Order
   UpdateOrder();
}

//Update the trailing stop and the take profit
void UpdateOrder() {
	
	bool res = false;
	double stopLoss, takeProfit, midVolatility;
	
	midVolatility = MyVolatility/2;
	
	//update BUY
	if(OrderType() == OP_BUY ) {
		stopLoss = MathMin(Ask - midVolatility, VolatilityLow);
		takeProfit = MathMax (Ask + midVolatility , VolatilityHight);
		
		res = OrderModify(OrderTicket(),OrderOpenPrice(),Ask-stopLoss, Ask+takeProfit,0, Blue);
		
	//update SELL
	} else {
		stopLoss = MathMin(Ask - midVolatility, VolatilityHight);
		takeProfit = MathMax (Ask + midVolatility , VolatilityLow);
		
		res = OrderModify(OrderTicket(),OrderOpenPrice(),Bid+stopLoss, Bid-takeProfit,0, Purple);
	}
	
	if(!res) PrintError("OrderModify");
		 
}

// Close Sell Order
//TODO: only 1 for the moment
void CloseOrder()
{
	bool res;
	
	if(OrderType() == OP_BUY ) {
		res = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(), MODE_BID), MySlippage, Orange);
	} else {
		res = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(), MODE_ASK), MySlippage, Orange);
	}
	
	if(!res)
      PrintError("OrderClose");
}

// Returns the number of total open orders for this Symbol and MagicNumber
int TotalOpenOrders()
{
   int total_orders = 0;
   
   for(int order = 0; order < OrdersTotal(); order++) 
   {
      if(OrderSelect(order,SELECT_BY_POS,MODE_TRADES)==false) break;
      
      if(OrderMagicNumber() == MagicNumber && OrderSymbol() == _Symbol)
         {
            total_orders++;
         }
   }
   
   return(total_orders);
}

//Checks and update the open Order
void CheckOpenOrder()
{   
	//Only 1 oder can be open.
    if(OrderMagicNumber() == MagicNumber && OrderSymbol() == _Symbol)
     {			
            //check buy trend
			if( (OrderType() == OP_BUY ) && (Close[0] > Open[0] && Close[0] > Close[1]) )
			   {
				  UpdateOrder();
			   }
			//check sell trend
			if( (OrderType() == OP_SELL ) && (Close[0] < Open[0] && Close[0] < Close[1]) )
			   {
				  UpdateOrder();
			   }
     }
}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+

   
// Get My Points   
double MyPoint()
{
   double CalcPoint = 0;
   
   if(_Digits == 2 || _Digits == 3) CalcPoint = 0.01;
   else if(_Digits == 4 || _Digits == 5) CalcPoint = 0.0001;
   
   return(CalcPoint);
}


// Get My Slippage
int MySlippage()
{
   int CalcSlippage = 0;
   
   if(_Digits == 2 || _Digits == 4) CalcSlippage = Slippage;
   else if(_Digits == 3 || _Digits == 5) CalcSlippage = Slippage * 10;
   
   return(CalcSlippage);
}

   
// Check if there is a new bar
bool IsNewBar()   
{        
   static datetime LastBarTime=0;
   datetime ThisBarTime = Time[0];
      
   if (ThisBarTime == LastBarTime)
   {
      return(false);
   }
   else
   {
      LastBarTime = ThisBarTime;
      return(true);
   }
}   

   
//Returns true if the current time is in the valid windows time ( eg: 9h30 - 22h30)
bool IsTradingTime()
{
	int hour = Hour();
	int minute = Minute();
	Print("Hour: ", hour , " Minute: ", minute);
	
	if( ((hour > StartingHour) ||  (hour >= StartingHour && minute > StartingMinute) )
		&& ((hour > StartingHour) ||  (hour >= StartingHour && minute > StartingMinute) ) )
		return true;
		
	return false;
}



//Update the volatility based the last days
double MyVolatility()
{
	bool res = false;
	double volatility;
	int shift;
	
	shift = iBarShift(NULL, PERIOD_D1, iTime(NULL,PERIOD_D1,Day_Volatility_Back));
	
	VolatilityHight = iHigh(NULL, PERIOD_D1, shift);
	VolatilityLow = iLow(NULL, PERIOD_D1, shift);
	
	volatility = VolatilityHight - VolatilityLow;
	
	Print("VolatilityHight : ", VolatilityHight, " | VolatilityLow : " , VolatilityLow, " | MyVolatility : ", volatility);
	
	return volatility;
}


//Calculate my Lot size
double MyLotSize()
{
   double oneLotMargin, freeMargin, lotMM, lotStep, committed, volatility;
   long leverage;
   
  oneLotMargin = MarketInfo(Symbol(),MODE_MARGINREQUIRED);
  freeMargin = AccountFreeMargin();
  lotStep = MarketInfo(Symbol(),MODE_LOTSTEP);
  leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
  
  lotMM = freeMargin/oneLotMargin * Risk/100;
  lotMM = NormalizeDouble(lotMM/lotStep,0) * lotStep;
  
  
   committed = lotMM * oneLotMargin;
   volatility = MyVolatility/2 * oneLotMargin * leverage;
   
   //the money committed must be higher than Volatility committed
   if(committed <  volatility  ) lotMM = 0;
   
  Print("OneLotMargin :", oneLotMargin);
  Print("FreeMargin :", freeMargin);
  Print("lotMM :", lotMM);
  Print("LotStep :", lotStep);
  Print("lotMM :", lotMM);
  Print("leverage :", leverage);
  Print("committed :", committed);
  Print("volatility :", volatility);
  
   return lotMM;
}

void PrintError (string fct) 
{
   string message;
   
		 message = StringConcatenate("Error in ", fct, ". Error code=#" , GetLastError());
		 Print(message);
		 if(!SendNotification(message)) 
		   Print("Error in SendNotification. Error code=#" ,GetLastError());   
      else Print("Order closed successfully.");
}