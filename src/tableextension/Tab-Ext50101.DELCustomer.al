tableextension 50101 "DEL Customer" extends Customer
{
    fields
    {
        field(50000; "Rejected Amount"; Decimal)
        {
            Caption = 'Rejected Amount', comment = 'ESP="Importe dotado"';
            Editable = false;
            TableRelation = "Cust. Ledger Entry" WHERE("Customer No." = FIELD("No."), "Amount to Redraw" = FILTER(<> 0), "Rejected Doubtful Debt" = CONST(true));
            FieldClass = FlowField;
            CalcFormula = Sum("Cust. Ledger Entry"."Amount to Redraw" WHERE("Rejected Doubtful Debt" = CONST(true), "Amount to Redraw" = FILTER(<> 0), "Customer No." = FIELD("No.")));
        }
    }

}