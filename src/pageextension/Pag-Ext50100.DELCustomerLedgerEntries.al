pageextension 50100 "DEL Customer Ledger Entries" extends "Customer Ledger Entries"
{
    layout
    {
        addafter("Document Status")
        {
            field("Rejected Amount"; Rec."Rejected Amount")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Amount to Redraw"; Rec."Amount to Redraw")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Redrawn Amount"; Rec."Redrawn Amount")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Rejected Doubtful Debt"; Rec."Rejected Doubtful Debt")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Redrawn Doubtful Debt"; Rec."Redrawn Doubtful Debt")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Initial Doub. Debt Entry No."; Rec."Initial Doub. Debt Entry No.")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Last Doub. Debt Entry No."; Rec."Last Doub. Debt Entry No.")
            {
                ApplicationArea = All;
            }
        }

    }

    actions
    {
        addafter(IncomingDocument)
        {
            action(Reject)
            {
                ApplicationArea = All;
                Caption = 'Reject', comment = 'ESP="Dotar"';
                Image = Reject;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Ellipsis = true;
                Scope = Page;

                trigger OnAction()
                var
                    rlCustomer: Record Customer;
                begin
                    //ES_TA_SM_001 (DFS) 26-07-2016: Provide and unprovide doubtful debts
                    CLEAR(rlCustomer);
                    IF rlCustomer.GET(Rec."Customer No.") THEN
                        rlCustomer.CheckBlockedCustOnJnls(rlCustomer, Rec."Document Type", FALSE);
                    fReject;
                    //ES_TA_SM_001 (DFS) 26-07-2016: Provide and unprovide doubtful debts
                end;
            }
            action(Redraw)
            {
                ApplicationArea = All;
                Caption = 'Redraw', comment = 'ESP="Desdotar"';
                Image = RefreshVoucher;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Ellipsis = true;
                Scope = Page;

                trigger OnAction()
                var
                    rlCustomer: Record Customer;
                begin
                    //ES_TA_SM_001 (DFS) 26-07-2016: Provide and unprovide doubtful debts
                    CLEAR(rlCustomer);
                    IF rlCustomer.GET(Rec."Customer No.") THEN
                        rlCustomer.CheckBlockedCustOnJnls(rlCustomer, Rec."Document Type", FALSE);
                    fRedraw;
                    //ES_TA_SM_001 (DFS) 26-07-2016: Provide and unprovide doubtful debts
                end;
            }
        }
    }
    //ES0011 (DFS) 26-07-2016: Provide and unprovide doubtful debts
    procedure fReject()
    var
        rlCustLedgerEntry: record "Cust. Ledger Entry";
        rlCustLedgerEntry2: record "Cust. Ledger Entry";
    begin


        Rec.TESTFIELD("Remaining Amount");

        CLEAR(rlCustLedgerEntry);
        CurrPage.SETSELECTIONFILTER(rlCustLedgerEntry);
        IF NOT rlCustLedgerEntry.FIND('-') THEN
            EXIT;
        rlCustLedgerEntry2.MARKEDONLY(TRUE);
        REPORT.RUNMODAL(REPORT::"Reject invoices", TRUE, FALSE, rlCustLedgerEntry);

    end;
    //ES0011 (DFS) 26-07-2016: End.


    //ES0011 (DFS) 26-07-2016: Provide and unprovide doubtful debts

    procedure fRedraw()
    var
        rlCustLedgerEntry: record "Cust. Ledger Entry";
        rlCustLedgerEntry2: record "Cust. Ledger Entry";

    begin
        Rec.TESTFIELD("Rejected Doubtful Debt", TRUE);
        Rec.TESTFIELD("Remaining Amount");

        CLEAR(rlCustLedgerEntry);
        CurrPage.SETSELECTIONFILTER(rlCustLedgerEntry);
        IF NOT rlCustLedgerEntry.FIND('-') THEN
            EXIT;
        rlCustLedgerEntry2.MARKEDONLY(TRUE);
        REPORT.RUNMODAL(REPORT::"Redraw invoices", TRUE, FALSE, rlCustLedgerEntry);
    end;
    //ES0011 (DFS) 26-07-2016: End.


}