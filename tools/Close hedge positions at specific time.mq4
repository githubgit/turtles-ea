//|$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//|     Close Hedged orders at certain time
//|   
//|$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#define     NL    "\n"

extern string textHedge="Broker time to run OrderCloseBy for relevant orders";
extern string TimeToCloseHedge = "23:55";
extern string textCloseAll="If remaining orders (hedge hedged market/pending) should be closed";
extern bool CloseAllAlongWithHedge = true;

//+-------------+
//| Custom init |
//|-------------+
int init()
  {
    EventSetMillisecondTimer(1);//every 1 ms
    return 0;
  }

//+----------------+
//| Custom DE-init |
//+----------------+
int deinit()
  {
    return 0;
  }

void OnTimer(){
   datetime timeToClose = StrToTime(TimeToCloseHedge); 
   if(OrdersTotal()>0){
   
   int closeHour = TimeHour(timeToClose); //0,1,2..23
   int closeMinute = TimeMinute(timeToClose); //0,..59
   //Print("closeHour: ", closeHour, " closeMinute: ", closeMinute);
   //Print("Current Hour: ", Hour(), " Minute: ", Minute());
   
      if(MarketInfo(Symbol(),MODE_TRADEALLOWED)==1 && Hour()==closeHour && Minute()==closeMinute){
          Print("Closing hedged orders with OrderCloseBy...");
          closeHedgeOrders();
          Print("Done");
          
          if(CloseAllAlongWithHedge){
             Print("Closing pending orders...");
             ClosePendingOrdersOnly();
             Print("Done");
             //close non hedged orders too
             if (OrdersTotal() > 0 ) {
              Print("Closing non hedged orders and pending orders...");
              CloseAll(); 
              Print("Done");
             }
          }
      };
   }
}

//+------------------------------------------------------------------------+
//| Closes everything
//+------------------------------------------------------------------------+
void CloseAll()
{
   int i;
   bool result = false;

   while(OrdersTotal()>0)
   {
      // Close open positions first to lock in profit/loss
      for(i=OrdersTotal()-1;i>=0;i--)
      {
         if(OrderSelect(i, SELECT_BY_POS)==false) continue;

         result = false;
         if ( OrderType() == OP_BUY)   result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 15, Red );
         if ( OrderType() == OP_SELL)  result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 15, Red );
      }
      for(i=OrdersTotal()-1;i>=0;i--)
      {
         if(OrderSelect(i, SELECT_BY_POS)==false) continue;

         result = false;
         if ( OrderType()== OP_BUYSTOP)  result = OrderDelete( OrderTicket() );
         if ( OrderType()== OP_SELLSTOP)  result = OrderDelete( OrderTicket() );
         if ( OrderType()== OP_BUYLIMIT)  result = OrderDelete( OrderTicket() );
         if ( OrderType()== OP_SELLLIMIT)  result = OrderDelete( OrderTicket() );
      }
      Sleep(10);
   }
}

//+------------------------------------------------------------------------+
//| cancels all pending orders 
//+------------------------------------------------------------------------+
void ClosePendingOrdersOnly()
{
  for(int i=OrdersTotal()-1;i>=0;i--)
 {  bool result = false;
    result = OrderSelect(i, SELECT_BY_POS);
    
        if ( OrderType()== OP_BUYSTOP)   result = OrderDelete( OrderTicket() );
        if ( OrderType()== OP_SELLSTOP)  result = OrderDelete( OrderTicket() );
        if ( OrderType()== OP_BUYLIMIT)   result = OrderDelete( OrderTicket() );
        if ( OrderType()== OP_SELLLIMIT)  result = OrderDelete( OrderTicket() );
  }
  return; 
  }

void closeHedgeOrders(){
  if(OrdersTotal()>1){
     for(int i=OrdersTotal()-1;i>=0;i--){
       int buyTicket;
       int sellTicket;
       bool result;
       result = OrderSelect(i, SELECT_BY_POS);
       
           if ( OrderType() == OP_BUY) {
               buyTicket = OrderTicket();
               Print("buyTicket: ", buyTicket);
               double buyLots = OrderLots();
               
               for(int k=OrdersTotal()-1;k>=0;k--){
               
                  if (k!=i){
                   result = OrderSelect(k, SELECT_BY_POS);
                     if( OrderType() == OP_SELL && OrderLots() == buyLots){
                        sellTicket = OrderTicket();
                        while(true){
                           Print("Closing hedged: ", buyTicket, " by ", sellTicket);
                           result = OrderCloseBy(sellTicket,buyTicket);
                           if(result){
                              Print("Hedged orders are closed");
                              break;
                           }
                           else {
                              Print("Error closing hedged: ", GetLastError()," Retry in 10ms");
                              Sleep(10);
                           }
                        }
                     }
                  }
                  else
                   continue;
               }
           }
     }
  }
}

//+-----------+
//| Main      |
//+-----------+
int start()
  {

 return 0;
}