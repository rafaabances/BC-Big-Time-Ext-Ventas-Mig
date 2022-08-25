codeunit 50100 "Reject Invoices"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertGLEntryBuffer', '', false, false)]
    local procedure fCompleteDoubtfulFields(var TempGLEntryBuf: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line"; var BalanceCheckAmount: Decimal; var BalanceCheckAmount2: Decimal; var BalanceCheckAddCurrAmount: Decimal; var BalanceCheckAddCurrAmount2: Decimal; var NextEntryNo: Integer; var TotalAmount: Decimal; var TotalAddCurrAmount: Decimal; var GLEntry: Record "G/L Entry");
    begin
        //ES_TA_SM_001ES0011 (DFS) 26-07-2016: Provide and unprovide doubtful debts
        IF GenJournalLine."Doubtful Debt Provision" THEN
            TempGLEntryBuf."Doubtful Debt Provision" := TRUE;
        TempGLEntryBuf."Doubtful Debt Entry No." := GenJournalLine."Initial Doub. Debt Entry No.";
        IF GenJournalLine."Doubful Debt Unprovision" THEN
            TempGLEntryBuf."Doubtful Debt Unprovision" := TRUE;
        TempGLEntryBuf."Doubtful Debt Entry No." := GenJournalLine."Initial Doub. Debt Entry No.";
        //ES0011 (DFS) 26-07-2016: End.
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostCustOnAfterInitCustLedgEntry', '', false, false)]
    local procedure fUpdateCustLedgerEntries(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry");
    begin
        //ES0011 (DFS) 26-07-2016: Provide and unprovide doubtful debts
        IF GenJournalLine."Doubtful Debt Provision" THEN BEGIN
            CustLedgEntry."Rejected Doubtful Debt" := TRUE;
            CustLedgEntry."Initial Doub. Debt Entry No." := GenJournalLine."Initial Doub. Debt Entry No.";
            CustLedgEntry."Last Doub. Debt Entry No." := GenJournalLine."Last Doub. Debt Entry No.";
            IF GenJournalLine."Doubfutl Debt Account" THEN BEGIN
                fUpdateCustLedgerEntriesAux(GenJournalLine, TRUE);
                CustLedgEntry."Rejected Amount" += ABS(GenJournalLine.Amount);
                CustLedgEntry."Amount to Redraw" += ABS(GenJournalLine.Amount);
                CustLedgEntry."Rejected Doubtful Debt" := TRUE;
            END;
        END;
        IF GenJournalLine."Doubful Debt Unprovision" THEN BEGIN
            CustLedgEntry."Initial Doub. Debt Entry No." := GenJournalLine."Initial Doub. Debt Entry No.";
            CustLedgEntry."Last Doub. Debt Entry No." := GenJournalLine."Last Doub. Debt Entry No.";
            IF (GenJournalLine."Doubfutl Debt Account") THEN BEGIN
                CustLedgEntry."Redrawn Doubtful Debt" := TRUE;
                fUpdateCustLedgerEntriesAux(GenJournalLine, FALSE);
            END ELSE BEGIN
                CustLedgEntry."Redrawn Doubtful Debt" := TRUE;
            END;
        END;
        //ES0011 (DFS) 26-07-2016: End.
    end;



    procedure fUpdateCustLedgerEntriesAux(pGenJournalLine: Record "Gen. Journal Line"; pProvision: Boolean)

    begin
        //ES0011 (DFS) 26-07-2016: Provide and unprovide doubtful debts
        IF pProvision THEN BEGIN
            fCompleteAmountFields(pGenJournalLine."Last Doub. Debt Entry No.", ABS(pGenJournalLine.Amount), 0);
            fUpdateInitialLedgerEntry(pGenJournalLine."Last Doub. Debt Entry No.");
        END ELSE BEGIN
            fCompleteAmountFields(pGenJournalLine."Last Doub. Debt Entry No.", 0, ABS(pGenJournalLine.Amount));
        END;
        //ES0011 (DFS) 26-07-2016: End.
    end;

    local procedure fCompleteAmountFields(pCustomerEntryNo: Integer; pRejectedAmount: Decimal; pRedrawnAmount: Decimal)
    var
        rlCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        //ES0011 (DFS) 26-07-2016: Provide and unprovide doubtful debts
        CLEAR(rlCustLedgerEntry);
        rlCustLedgerEntry.GET(pCustomerEntryNo);
        IF pRejectedAmount <> 0 THEN BEGIN
            rlCustLedgerEntry."Rejected Amount" += pRejectedAmount;
        END;
        IF pRedrawnAmount <> 0 THEN BEGIN
            rlCustLedgerEntry."Redrawn Amount" += pRedrawnAmount;
            rlCustLedgerEntry."Amount to Redraw" -= pRedrawnAmount;
        END;
        rlCustLedgerEntry.MODIFY;
        //ES0011 (DFS) 26-07-2016: End.
    end;

    local procedure fUpdateInitialLedgerEntry(pEntryNo: Integer)
    var
        rlCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        //ES0011 (DFS) 26-07-2016: Provide and unprovide doubtful debts
        CLEAR(rlCustLedgerEntry);
        rlCustLedgerEntry.GET(pEntryNo);
        rlCustLedgerEntry."Rejected Doubtful Debt" := TRUE;
        IF rlCustLedgerEntry."Document Type" = rlCustLedgerEntry."Document Type"::Invoice THEN BEGIN
            rlCustLedgerEntry."Initial Doub. Debt Entry No." := rlCustLedgerEntry."Entry No.";
            rlCustLedgerEntry."Last Doub. Debt Entry No." := rlCustLedgerEntry."Entry No.";
        END;
        rlCustLedgerEntry.MODIFY;
        //ES0011 (DFS) 26-07-2016: End.
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInitGLEntry', '', false, false)]
    local procedure OnBeforeInitGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var GLAccNo: Code[20]; SystemCreatedEntry: Boolean; Amount: Decimal; AmountAddCurr: Decimal);
    var
        AccNo: Code[20];
        CustPostingGr: Record "Customer Posting Group";
    begin
        //ES0011 (DFS) 26-07-2016: Provide and unprovide doubtful debts
        IF GenJournalLine."Doubfutl Debt Account" THEN
            AccNo := CustPostingGr."Doubtful debts account"
        //ES0011 (DFS) 26-07-2016: End.
    end;
}