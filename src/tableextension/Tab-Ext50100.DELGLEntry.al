tableextension 50100 "DEL G/L Entry" extends "G/L Entry"
{
    fields
    {
        field(50000; "Doubtful Debt Provision"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Doubtful Debt Provision', comment = 'ESP="Dotación moroso"';
        }
        field(50001; "Doubtful Debt Unprovision"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Doubtful Debt Unprovision', comment = 'ESP="Desdotación moroso"';

        }
        field(50002; "Doubtful Debt Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Doubtful Debt Entry No.', comment = 'ESP="Nº mov. de dudoso cobro inicial"';

        }
    }

}