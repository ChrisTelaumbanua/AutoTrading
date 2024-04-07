//+------------------------------------------------------------------+
//|                                                     ADX_EA.mq5   |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                              https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict

// Input parameters
input double LotSize = 0.01;
input double TakeProfit = 15000; // Take Profit dalam rupiah
input ENUM_TIMEFRAMES TimeFrame = PERIOD_M15;
input string StartTime = "07:00"; // Waktu mulai trading
input string StopTime = "23:59";  // Waktu berhenti trading

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Set time filter
    datetime startTrading = StrToTime(StartTime);
    datetime stopTrading = StrToTime(StopTime);
    
    // Main loop
    while (!IsStopped())
    {
        datetime now = TimeLocal();
        
        // Check if it's trading time
        if (now >= startTrading && now <= stopTrading)
        {
            // Execute trading strategy every 16 minutes
            if (TimeMinute(now) % 16 == 0)
            {
                ExecuteStrategy();
            }
        }
        
        // Wait for the next minute
        Sleep(60000);
    }
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Function to execute trading strategy                             |
//+------------------------------------------------------------------+
void ExecuteStrategy()
{
    double plusDI, minusDI;
    // Calculate ADI indicator values
    if (CalculateADIValues(plusDI, minusDI))
    {
        // Entry conditions for Buy
        if (plusDI > 25 && plusDI[1] < 25)
        {
            OpenPosition(OP_BUY);
        }
        else if (plusDI < 25 && minusDI < 25 && plusDI > plusDI[1] && minusDI > minusDI[1])
        {
            OpenPosition(OP_BUY);
        }
        // Entry conditions for Sell
        else if (minusDI > 25 && minusDI[1] < 25)
        {
            OpenPosition(OP_SELL);
        }
        else if (minusDI < 25 && plusDI < 25 && minusDI > minusDI[1] && plusDI > plusDI[1])
        {
            OpenPosition(OP_SELL);
        }
    }
}

//+------------------------------------------------------------------+
//| Function to calculate ADI indicator values                       |
//+------------------------------------------------------------------+
bool CalculateADIValues(out double plusDI, out double minusDI)
{
    int handle = iADX(_Symbol, TimeFrame, 2, PRICE_CLOSE);
    if (handle == INVALID_HANDLE)
    {
        Print("Failed to get ADI indicator handle!");
        return false;
    }
    
    // Get ADI values
    plusDI = iADX(NULL, TimeFrame, 2, ADX_PLUSDI, 0);
    minusDI = iADX(NULL, TimeFrame, 2, ADX_MINUSDI, 0);
    
    // Free indicator handle
    IndicatorRelease(handle);
    return true;
}

//+------------------------------------------------------------------+
//| Function to open position                                        |
//+------------------------------------------------------------------+
void OpenPosition(int tradeType)
{
    double price = tradeType == OP_BUY ? Ask : Bid;
    int ticket = OrderSend(_Symbol, tradeType, LotSize, price, 3, 0, 0, "", 0, 0, clrNONE);
    if(ticket > 0){
        OrderSelect(ticket, SELECT_BY_TICKET);
        double takeProfitPrice = tradeType == OP_BUY ? price + TakeProfit / 10_000 : price - TakeProfit / 10_000;
        OrderTakeProfit(OrderTicket(), takeProfitPrice);
    }
}
