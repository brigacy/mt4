//+------------------------------------------------------------------+
//|                                                    MyFirstEA.mq4 |
//|                                        Copyright 2014, ForexBoat |
//|                                         https://forexboat.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, brigacy"
#property link      ""
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      Alert("Expert Advisor has been launched");
      
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
      Alert("Expert Advisor terminated");
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
      Alert("Your new Bid price is: " + string(Bid));
   
  }
//+------------------------------------------------------------------+