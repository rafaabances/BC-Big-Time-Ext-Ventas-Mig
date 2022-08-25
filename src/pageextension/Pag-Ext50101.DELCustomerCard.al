pageextension 50101 "DEL Customer Card" extends "Customer Card"
{
    layout
    {
        addafter("Balance (LCY)")
        {
            field("Rejected Amount"; Rec."Rejected Amount")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addafter("Ledger E&ntries")
        {
            action("Doubtful Debts Entries")
            {
                ApplicationArea = All;
                Caption = 'Reject', comment = 'ESP="Mov. dotación morosos"';
                Image = Reject;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Page;

                trigger OnAction()
                var
                    rlCustLedgerEntry: Record "Cust. Ledger Entry";
                    plCustomerLedgerEntries: page "Customer Ledger Entries";
                begin
                    //ES0011 (DFS) 26-07-2016: Provide and unprovide doubtful debts
                    CLEAR(rlCustLedgerEntry);
                    rlCustLedgerEntry.SETCURRENTKEY("Customer No.", "Posting Date", "Currency Code");
                    rlCustLedgerEntry.SETRANGE("Customer No.", Rec."No.");
                    rlCustLedgerEntry.SETRANGE("Rejected Doubtful Debt", TRUE);
                    rlCustLedgerEntry.SETFILTER("Amount to Redraw", '<>%1', 0);
                    plCustomerLedgerEntries.SETTABLEVIEW(rlCustLedgerEntry);
                    plCustomerLedgerEntries.RUN;
                    //ES0011 (DFS) 26-07-2016: End.
                end;
            }

        }
    }
}