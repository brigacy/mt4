//+------------------------------------------------------------------+
//|                                                  My First EA.mq4 |
//|                                     MQL4 tutorial on quivofx.com |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "3.00"
#property strict

//--- input parameters
input int      TakeProfit=50;
input int      StopLoss=50;
input double   LotSize=0.1;
input int      Slippage=3;
input int      MagicNumber=5555;

//--- global variables
double MyPoint;
int    MySlippage;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   MyPoint = MyPoint();
   MySlippage = MySlippage();
   
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

   if(TotalOpenOrders() == 0 && IsNewBar() == true)
   { 
      // Check Buy Entry
      if(BuySignal() == true)
         {
            OpenBuy();
         }
      
      // Check Sell Entry
      else if(SellSignal() == true)
         {
            OpenSell();
         }  
   }
   
  }
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+

// Buy Logic
bool BuySignal()
{
   if(Close[1] > Open[1] && Close[2] > Open[2] && Close[3] > Open[3])
   {
      return(true);
   }
   else
   {
      return(false);
   }
}


// Sell Logic
bool SellSignal()
{
   if(Close[1] < Open[1] && Close[2] < Open[2] && Close[3] < Open[3])
   {
      return(true);
   }
   else
   {
      return(false);
   }
}
 
 
// Open Buy Order
void OpenBuy()
{
   // Open Buy Order
   int ticket = OrderSend(_Symbol,OP_BUY,LotSize,Ask,MySlippage,0,0,"BUY",MagicNumber);
      
      if(ticket<0)
      {
         Print("OrderSend failed with error #",GetLastError());
      }
      else
      {
         Print("OrderSend placed successfully");
      }
                 
   // Modify Buy Order
   bool res = OrderModify(ticket,OrderOpenPrice(),Ask-StopLoss*MyPoint,Ask+TakeProfit*MyPoint,0);
      
      if(!res)
      {
         Print("Error in OrderModify. Error code=",GetLastError());
      }
      else
      {
         Print("Order modified successfully.");
      }
}


// Open Sell Order
void OpenSell()
{
   //Open Sell Order
   int ticket = OrderSend(_Symbol,OP_SELL,LotSize,Bid,MySlippage,0,0,"SELL",MagicNumber);
      
      if(ticket<0)
      {
         Print("OrderSend failed with error #",GetLastError());
      }
      else
      {
         Print("OrderSend placed successfully");
      }
                 
   // Modify Sell Order
   bool res = OrderModify(ticket,OrderOpenPrice(),Bid+StopLoss*MyPoint,Bid-TakeProfit*MyPoint,0);
      
      if(!res)
      {
         Print("Error in OrderModify. Error code=",GetLastError());
      }
      else
      {
         Print("Order modified successfully.");
      }    
}

   
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
   static datetime RegBarTime=0;
   datetime ThisBarTime = Time[0];
      
   if (ThisBarTime == RegBarTime)
   {
      return(false);
   }
   else
   {
      RegBarTime = ThisBarTime;
      return(true);
   }
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
