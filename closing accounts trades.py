    
def close_account_orders (runDate, runGroupName):
    start_time = time.time()
    
        
    
    ## Closing orders that are still pending:
    #########################################
    ##      1. Adjust the quantity of the pending orders. If the adjusted amount is 0 then cancel order. Otherwise change order.
    stmt = """
        SELECT A.ACCOUNT_ID, A.SYMBOL, A.RUN_GROUP_NAME, A.ENTER_MODEL_TIMESTAMP, 
                B.ordertype, B.ORDERID, B.ACTION, B.OCAGROUP,
                A.QTY, B.QTY IB_QTY
        FROM """ + d_account_trade_table_name + """ A
        JOIN D_ACCOUNT D
        ON A.ACCOUNT_ID = D.ACCOUNT_ID
        JOIN """ + d_ib_open_order_table_name + """ B
        ON A.SYMBOL = B.SYMBOL
        AND B.OCAGROUP IS NULL
        WHERE A.RUN_GROUP_NAME = '""" + runGroupName + """'
        AND '""" + runDate + """' >= D.CLOSE_DATE
        AND A.ENTER_PERMID IS NULL
        AND A.EXIT_TRADE_TIMESTAMP IS NULL
        GROUP BY A.SYMBOL, A.RUN_GROUP_NAME, A.ENTER_MODEL_TIMESTAMP, B.ordertype, B.ORDERID, B.ACTION
        """
    df = TiDB.db_query (stmt)
    
    if isinstance(df, pd.DataFrame):
        if (df.count().max() > 0):
            # Open IB Connection
            TiTrade.create_api_connection(2)
            time.sleep (3)
            
            for index, rows in df.iterrows():
                if rows['QTY'] == rows['IB_QTY']:
                    try:
                        tradeDF = TiTrade.cancel_orders(rows['ORDERID'])
                        time.sleep (5)
                    except:
                        sms = "{}".format("There is a problem cancelling open order for " + rows['SYMBOL'])
                        TiSMS.send_sms(sms)
                        
                elif rows['QTY'] < rows['IB_QTY']:
                    try:
                        tradeDF = TiTrade.changeOrder(rows['ORDERID'],  {'SYMBOL':rows['SYMBOL']}, rows['ORDERTYPE'], rows['ACTION'], rows['IB_QTY'] - rows['QTY'])
                        stmt = """
                            SELECT B.SYMBOL, B.ordertype, B.ORDERID, B.ACTION, B.OCAGROUP,
                                    A.QTY, B.QTY IB_QTY
                            FROM """ + d_ib_open_order_table_name + """ B
                            WHERE B.SYMBOL = '""" + rows['SYMBOL'] + """'
                            """                        
                        dfOrder = TiDB.db_query (stmt)
                        
                        if isinstance(dfOrder, pd.DataFrame):
                            if (dfOrder.count().max() > 0):
                                for index, rowsOrder in dfOrder.iterrows():
                                    tradeDF = TiTrade.changeOrder(rowsOrder['ORDERID'],  {'SYMBOL':rowsOrder['SYMBOL']}, rowsOrder['ORDERTYPE'], rowsOrder['ACTION'], rows['IB_QTY'] - rows['QTY'])
                    except:
                        sms = "{}".format("There is a problem modifying open order for " + rows['SYMBOL'])
                        TiSMS.send_sms(sms)
                
    
    ##      2. update D_ACCOUNT_TRADE with the right details
                stmt = """
                    SELECT A.ACCOUNT_ID, A.SYMBOL, A.RUN_GROUP_NAME, A.ENTER_MODEL_TIMESTAMP, 
                            '""" + runDate + """' EXIT_TRADE_TIMESTAMP, 'CLOSED' EXIT_TYPE
                    FROM """ + d_account_trade_table_name + """ A
                    WHERE SYMBOL = '""" + rows['SYMBOL'] + """'
                    AND ACCOUNT_ID = '""" + rows['ACCOUNT_ID'] + """'
                    AND RUN_GROUP_NAME = '""" + rows['RUN_GROUP_NAME'] + """'
                    AND ENTER_MODEL_TIMESTAMP = '""" + rows['ENTER_MODEL_TIMESTAMP'] + """'
                    """
                dfSymbol = TiDB.db_query (stmt)
                
                if isinstance(dfSymbol, pd.DataFrame):
                    if (dfSymbol.count().max() > 0):
                        TiDB.db_merge(d_account_trade_table_name, dfSymbol)   
                    # Drop IB Connection
            
            TiTrade.drop_api_connection()
            time.sleep (3)    
                        
    ## Closing orders that are in production:
    #########################################
    ##      1. Reverse the production order. If the qty for account is the same of position then change ethe STP order to MKT. Otherwise submit a MKT order .
    stmt = """
        SELECT A.ACCOUNT_ID, A.SYMBOL, A.RUN_GROUP_NAME, A.ENTER_MODEL_TIMESTAMP, A.QTY,
                CASE WHEN B.ORDERTYPE = 'LMT' THEN B.ordertype END TP_ORDER_TYPE, 
                CASE WHEN B.ORDERTYPE = 'LMT' THEN B.ORDERID END TP_ORDER_ID, 
                CASE WHEN B.ORDERTYPE = 'LMT' THEN B.ACTION END TP_ACTION, 
                CASE WHEN B.ORDERTYPE = 'LMT' THEN B.OCAGROUP END TP_OCAGROUP,
                CASE WHEN B.ORDERTYPE = 'LMT' THEN B.QTY END TP_IB_QTY, 
                -----------
                CASE WHEN B.ORDERTYPE = 'STP' THEN B.ordertype END SL_ORDER_TYPE, 
                CASE WHEN B.ORDERTYPE = 'STP' THEN B.ORDERID END SL_ORDER_ID, 
                CASE WHEN B.ORDERTYPE = 'STP' THEN B.ACTION END SL_ACTION, 
                CASE WHEN B.ORDERTYPE = 'STP' THEN B.OCAGROUP END SL_OCAGROUP,
                CASE WHEN B.ORDERTYPE = 'STP' THEN B.QTY END SL_IB_QTY
        FROM """ + d_account_trade_table_name + """ A
        JOIN D_ACCOUNT D
        ON A.ACCOUNT_ID = D.ACCOUNT_ID
        JOIN """ + d_ib_open_order_table_name + """ B
        ON A.SYMBOL = B.SYMBOL
        AND B.OCAGROUP IS NULL
        WHERE A.RUN_GROUP_NAME = '""" + runGroupName + """'
        AND '""" + runDate + """' >= D.CLOSE_DATE
        AND A.ENTER_PERMID IS NULL
        AND A.EXIT_TRADE_TIMESTAMP IS NULL
        GROUP BY A.SYMBOL, A.RUN_GROUP_NAME, A.ENTER_MODEL_TIMESTAMP, A.QTY
        """
    df = TiDB.db_query (stmt)
    
    if isinstance(df, pd.DataFrame):
        if (df.count().max() > 0):
            # Open IB Connection
            TiTrade.create_api_connection(2)
            time.sleep (3)
            
            for index, rows in df.iterrows():
                if rows['SL_IB_QTY'] == rows['QTY']:    
                    try:
                        tradeDF = TiTrade.changeOrder(rows['SL_ORDER_ID'],  {'SYMBOL':rows['SYMBOL']}, 'MKT', rows['SL_ACTION'], rows['SL_IB_QTY'])
                        time.sleep (5)
                    except:
                        sms = "{}".format("There is a problem executing the stop-loss order for " + rows['SYMBOL'])
                        TiSMS.send_sms(sms)
                elif rows['SL_IB_QTY'] > rows['QTY']:    
                    try:
                        tradeDF = TiTrade.placeOrder(orderContract = {'SYMBOL':rows['SYMBOL']}, 
                                               orderType = 'MKT', 
                                               action = rows['TP_ACTION'].upper(), 
                                               quantity = rows['QTY']
                                               )
                        time.sleep(5)
                        tradeDF = TiTrade.changeOrder(rows['SL_ORDER_ID'],  {'SYMBOL':rows['SYMBOL']}, rowsOrder['SL_ORDER_TYPE'], rows['SL_ACTION'], rows['SL_IB_QTY'] - rows['QTY'])
                        time.sleep(5)
                        tradeDF = TiTrade.changeOrder(rows['TP_ORDER_ID'],  {'SYMBOL':rows['SYMBOL']}, rowsOrder['TP_ORDER_TYPE'], rows['TP_ACTION'], rows['TP_IB_QTY'] - rows['QTY'])
                        time.sleep (5)
                    except:
                        sms = "{}".format("There is a problem modifying SL and TP orders for " + rows['SYMBOL'])
                        TiSMS.send_sms(sms)

                
    ##      2. update D_ACCOUNT_TRADE with the right details
                stmt = """
                    SELECT A.ACCOUNT_ID, A.SYMBOL, A.RUN_GROUP_NAME, A.ENTER_MODEL_TIMESTAMP, 
                            '""" + runDate + """' EXIT_TRADE_TIMESTAMP, 'CLOSED' EXIT_TYPE
                    FROM """ + d_account_trade_table_name + """ A
                    WHERE SYMBOL = '""" + rows['SYMBOL'] + """'
                    AND ACCOUNT_ID = '""" + rows['ACCOUNT_ID'] + """'
                    AND RUN_GROUP_NAME = '""" + rows['RUN_GROUP_NAME'] + """'
                    AND ENTER_MODEL_TIMESTAMP = '""" + rows['ENTER_MODEL_TIMESTAMP'] + """'
                    """
                dfSymbol = TiDB.db_query (stmt)
                
                if isinstance(dfSymbol, pd.DataFrame):
                    if (dfSymbol.count().max() > 0):
                        TiDB.db_merge(d_account_trade_table_name, dfSymbol)   
                    # Drop IB Connection
            
            TiTrade.drop_api_connection()
            time.sleep (3)    
