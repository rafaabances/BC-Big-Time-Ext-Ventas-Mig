tableextension 50103 "DEL Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(50000; "Doubtful Debt Provision"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Doubtful Debt Provision', comment = 'ESP="Dotación moroso"';
        }
        field(50001; "Doubful Debt Unprovision"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Doubful Debt Unprovision', comment = 'ESP="Desdotación moroso"';
        }
        field(50002; "Doubfutl Debt Account"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Doubfutl Debt Account', comment = 'ESP="Cuenta deuda moroso"';
        }
        field(50003; "Initial Doub. Debt Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Initial Doub. Debt Entry No.', comment = 'ESP="Nº mov. de dudoso cobro inicial"';
        }
        field(50004; "Last Doub. Debt Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Last Doub. Debt Entry No.', comment = 'ESP="Nº mov. de dudoso cobro último"';
        }


    }

}