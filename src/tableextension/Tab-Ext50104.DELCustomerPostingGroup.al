tableextension 50104 "DEL Customer Posting Group" extends "Customer Posting Group"
{
    fields
    {
        field(50000; "Late payment damage account"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Late payment damage account', comment = 'ESP="Cta. deterioro morosidad"';
            TableRelation = "G/L Account";
        }
        field(50001; "Late payment account"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Late payment account', comment = 'ESP="Cta. dotación morosidad"';
            TableRelation = "G/L Account";
        }
        field(50002; "Late payment release account"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Late payment release account', comment = 'ESP="Cta. desdotación morosidad"';
            TableRelation = "G/L Account";
        }
        field(50003; "Doubtful debts account"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Doubtful debts account', comment = 'ESP="Cta. dudoso cobro"';
            TableRelation = "G/L Account";
        }

    }

    // procedure fGetDoubtfulAccount(): Code[20]
    // var
    // begin
    //     //ES0011 (DFS) 26-07-2016: Provide and unprovide doubtful debts
    //     TESTFIELD("Doubtful debts account");
    //     EXIT("Doubtful debts account");
    //     //ES0011 (DFS) 26-07-2016: End

    // end;

}