tableextension 50105 "DEL CV Ledger Entry Buffer" extends "CV Ledger Entry Buffer"
{
    fields
    {
        field(50000; "Rejected Doubtful Debt"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Rejected Doubtful Debt', comment = 'ESP="Dotación moroso"';
        }
        field(50001; "Redrawn Doubtful Debt"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Redrawn Doubtful Debt', comment = 'ESP="Desdotación moroso"';
        }
        field(50002; "Initial Doub. Debt Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Initial Doub. Debt Entry No.', comment = 'ESP="Nº mov. de dudoso cobro inicial"';
        }
        field(50003; "Last Doub. Debt Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Last Doub. Debt Entry No.', comment = 'ESP="Nº mov. de dudoso cobro final"';
        }
        field(50004; "Rejected Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Rejected Amount', comment = 'ESP="Importe dotado"';
        }
        field(50005; "Redrawn Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Redrawn Amount', comment = 'ESP="Importe desdotado"';
        }
        field(50006; "Amount to Redraw"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Amount to Redraw', comment = 'ESP="Importe a recircular"';
        }
    }

}