pageextension 50103 "DEL Customer Posting Groups" extends "Customer Posting Groups"
{
    layout
    {
        addafter("Payment Tolerance Credit Acc.")
        {
            field("Doubtful debts account"; Rec."Doubtful debts account")
            {
                ApplicationArea = All;
            }
            field("Late payment damage account"; Rec."Late payment damage account")
            {
                ApplicationArea = All;
            }
            field("Late payment account"; Rec."Late payment account")
            {
                ApplicationArea = All;
            }
            field("Late payment release account"; Rec."Late payment release account")
            {
                ApplicationArea = All;
            }

        }
    }
}