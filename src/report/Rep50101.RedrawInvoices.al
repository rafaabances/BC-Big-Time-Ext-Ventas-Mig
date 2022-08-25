report 50101 "Redraw Invoices"
{
    Caption = 'Recircular efecs. a cobrar';
    UsageCategory = Administration;
    ProcessingOnly = true;
    ApplicationArea = All;
    Permissions = TableData "Cust. Ledger Entry" = imd, TableData "Vendor Ledger Entry" = imd, TableData "Cartera Doc." = imd, TableData "Posted Cartera Doc." = imd, TableData "Closed Cartera Doc." = imd;


    dataset
    {
        dataitem(CustLedgEntry; "Cust. Ledger Entry")
        {
            trigger OnPreDataItem()
            begin
                vReasonCode := rGenJnlBatch."Reason Code";
                rGenJnlTemplate.GET(vTemplName);
                vSourceCode := rGenJnlTemplate."Source Code";

                vWindow.OPEN(
                  Text51002);

                vDocCount := 0;

                rGenJnlLine.SETFILTER("Journal Template Name", vTemplName);
                rGenJnlLine.SETFILTER("Journal Batch Name", vBatchName);
                IF rGenJnlLine.FINDLAST THEN
                    vGenJnlLineNextNo := rGenJnlLine."Line No." + 10000
                ELSE
                    vGenJnlLineNextNo := 10000;
                vTransactionNo := rGenJnlLine."Transaction No." + 1;
            end;

            trigger OnAfterGetRecord()
            begin
                IF vNewDueDate < "Due Date" THEN
                    ERROR(
                      Text51003,
                      FIELDCAPTION("Due Date"),
                      FIELDCAPTION("Entry No."),
                      "Entry No.");
                vDocCount := vDocCount + 1;
                vWindow.UPDATE(1, vDocCount);

                fGenJnlLineInit;
                fCreateDoubtfulEntry;
                rGenJnlLine.INSERT;

                vNewDocAmount := -rGenJnlLine.Amount;
                vNewDocAmountLCY := -rGenJnlLine."Amount (LCY)";

                rCustomer.GET("Customer No.");
                rCustomer.TESTFIELD("Customer Posting Group");
                rCustPostingGr.GET(rCustomer."Customer Posting Group");


                fGenJnlLineInit;
                IF vNewPmtMethod = '' THEN
                    rGenJnlLine."Payment Method Code" := CustLedgEntry."Payment Method Code"
                ELSE
                    rGenJnlLine."Payment Method Code" := vNewPmtMethod;
                "Due Date" := vNewDueDate;
                fInsertGenJnlLine(
                  rGenJnlLine."Account Type"::Customer,
                  CustLedgEntry."Customer No.",
                  rGenJnlLine."Document Type"::" ",
                  vNewDocAmount,
                  vNewDocAmountLCY,
                  STRSUBSTNO(
                    Text51004,
                    CustLedgEntry."Document No.",
                    vDocNo),
                  vDocNo);



                "Document Status" := "Document Status"::Redrawn;
                MODIFY;

                fGenJnlLineInit;
                rCustPostingGr.TESTFIELD("Late payment damage account");
                fInsertGenJnlLine(
                  rGenJnlLine."Account Type"::"G/L Account",
                  rCustPostingGr."Late payment damage account",
                  rGenJnlLine."Document Type"::" ",
                  vNewDocAmount,
                  vNewDocAmountLCY,
                  STRSUBSTNO(
                    Text51004,
                    CustLedgEntry."Document No.",
                    vDocNo),
                  vDocNo);



                fGenJnlLineInit;
                rCustPostingGr.TESTFIELD("Late payment release account");
                fInsertGenJnlLine(
                  rGenJnlLine."Account Type"::"G/L Account",
                  rCustPostingGr."Late payment release account",
                  rGenJnlLine."Document Type"::" ",
                  -vNewDocAmount,
                  -vNewDocAmountLCY,
                  STRSUBSTNO(
                    Text51004,
                    CustLedgEntry."Document No.",
                    vDocNo),
                  vDocNo);
            end;

            trigger OnPostDataItem()
            begin
                vWindow.CLOSE;
                COMMIT;
                rGenJnlLine.RESET;
                rGenJnlTemplate.GET(vTemplName);
                rGenJnlLine.FILTERGROUP := 2;
                rGenJnlLine.SETRANGE("Journal Template Name", vTemplName);
                rGenJnlLine.FILTERGROUP := 0;
                cGenJnlManagement.SetName(vBatchName, rGenJnlLine);
                pGeneralJnlForm.SETTABLEVIEW(rGenJnlLine);
                pGeneralJnlForm.SETRECORD(rGenJnlLine);
                pGeneralJnlForm.SetJnlBatchName(vBatchName);
                pGeneralJnlForm.AllowClosing(TRUE);
                pGeneralJnlForm.RUNMODAL;

                MESSAGE(Text51005, vDocCount);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options', comment = 'ESP="Opciones"';
                    field(vPostingDate; vPostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date', comment = 'ESP="Fecha registro"';
                    }

                    field(NewDueDate; vNewDueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Due Date', comment = 'ESP="Nueva fecha vencimiento"';

                    }

                    field(NewPmtMethod; vNewPmtMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Payment Method', comment = 'ESP="Nueva forma pago"';
                        TableRelation = "Payment Method" WHERE("Create Bills" = CONST(False));
                    }


                    group(Include)
                    {
                        Caption = 'Auxiliary Journal', comment = 'ESP="Diario auxiliar"';
                        field(TemplateName; vTemplName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Template Name', comment = 'ESP="Nombre libro"';
                            TableRelation = "Gen. Journal Template".Name WHERE(Type = CONST(Doubtful), Recurring = CONST(false));

                            trigger OnValidate()
                            var
                                rlGenJournalTemplate: Record "Gen. Journal Template";
                            begin
                                IF vTemplName = '' THEN
                                    vBatchName := ''
                                ELSE BEGIN
                                    rlGenJournalTemplate.GET(vTemplName);
                                    rlGenJournalTemplate.TESTFIELD(Type, rlGenJournalTemplate.Type::Doubtful);
                                END;

                            end;
                        }


                        field(BatchName; vBatchName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Batch Name', comment = 'ESP="Nombre sección"';

                            TableRelation = "Gen. Journal Batch".Name;

                            trigger OnValidate()
                            begin
                                fBatchNameOnValidate;
                                fBatchNameOnAfterValidate;
                            end;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                IF vTemplName = '' THEN
                                    EXIT;

                                IF rGenJnlBatch.GET(vTemplName, Text) THEN;
                                rGenJnlBatch.SETRANGE("Journal Template Name", vTemplName);
                                IF PAGE.RUNMODAL(PAGE::"General Journal Batches", rGenJnlBatch) = ACTION::LookupOK THEN
                                    vBatchName := rGenJnlBatch.Name;
                            end;
                        }
                    }

                }
            }
        }

        trigger OnOpenPage()
        begin
            vPostingDate := WORKDATE;
            vTemplName := '';
            vBatchName := '';
        end;

    }

    trigger OnPreReport()
    var
        myInt: Integer;
    begin
        IF vNewDueDate = 0D THEN
            ERROR(Text51000);

        IF NOT rGenJnlBatch.GET(vTemplName, vBatchName) THEN
            ERROR(Text51001);
    end;


    var
        rCustomer: Record Customer;
        rCustPostingGr: Record "Customer Posting Group";
        rGenJnlTemplate: Record "Gen. Journal Template";
        rGenJnlBatch: Record "Gen. Journal Batch";
        rGenJnlLine: Record "Gen. Journal Line";
        rTempCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        cGenJnlManagement: Codeunit GenJnlManagement;
        pGeneralJnlForm: page "Del Doubtful Debt Journal";
        vWindow: Dialog;
        vTransactionNo: Integer;
        vPostingDate: Date;
        vBillGrPostingDate: Date;
        vBatchName: code[10];
        vTemplName: Code[10];
        vSourceCode: Code[10];
        vReasonCode: Code[10];
        vNewDocAmount: Decimal;
        vNewDocAmountLCY: Decimal;
        vGenJnlLineNextNo: Integer;
        vDocCount: Integer;
        vAccount: Code[20];
        vDocNo: Code[20];
        vNewDueDate: Date;
        vNewPmtMethod: Code[10];

        // Label / TextConstants

        Text51000: Label 'Indique la nueva fecha vencimiento para el efecto recirculado.';
        Text51001: Label 'Rellene el nombre del libro y la sección del diario con los valores apropiados.';
        Text51002: Label 'Recirculando           #1######';
        Text51003: Label 'La nueva fecha de vencimiento no puede ser anterior a la actual %1 en doc. %2%3';
        Text51004: Label 'Documento Recirculado %1/%2';
        Text51005: Label 'Se ha/n preparado %1 factura/s para recircular.';







    local procedure fCreateDoubtfulEntry()

    begin

        rGenJnlLine."Account Type" := rGenJnlLine."Account Type"::Customer;
        rGenJnlLine.VALIDATE("Account No.", CustLedgEntry."Customer No.");
        rGenJnlLine."Document Type" := rGenJnlLine."Document Type"::" ";
        rGenJnlLine."Document No." := CustLedgEntry."Document No.";
        rGenJnlLine."Bill No." := CustLedgEntry."Bill No.";
        rGenJnlLine.Description := STRSUBSTNO(
            Text51004,
            CustLedgEntry."Document No.",
            CustLedgEntry."Bill No.");
        rGenJnlLine.VALIDATE("Currency Code", CustLedgEntry."Currency Code");
        CustLedgEntry.CALCFIELDS("Remaining Amount", "Remaining Amt. (LCY)");
        rGenJnlLine.VALIDATE(Amount, -CustLedgEntry."Remaining Amount");
        rGenJnlLine.VALIDATE("Amount (LCY)", -CustLedgEntry."Remaining Amt. (LCY)");
        rGenJnlLine."Dimension Set ID" := rGenJnlLine."Dimension Set ID";
        rGenJnlLine."Initial Doub. Debt Entry No." := CustLedgEntry."Initial Doub. Debt Entry No.";
        rGenJnlLine."Last Doub. Debt Entry No." := CustLedgEntry."Entry No.";
        rGenJnlLine."Doubful Debt Unprovision" := TRUE;
        rGenJnlLine."Doubfutl Debt Account" := TRUE;
        rGenJnlLine."System-Created Entry" := TRUE;
        CustLedgEntry."Applies-to ID" := FORMAT(CustLedgEntry."Entry No.");
        CustLedgEntry."Amount to Apply" := -rGenJnlLine.Amount;
        CustLedgEntry.MODIFY;
        rGenJnlLine."Applies-to ID" := FORMAT(CustLedgEntry."Entry No.");

    end;

    local procedure fGenJnlLineInit()

    begin
        CLEAR(rGenJnlLine);
        rGenJnlLine.INIT;
        rGenJnlLine."Line No." := vGenJnlLineNextNo;
        vGenJnlLineNextNo := vGenJnlLineNextNo + 10000;
        rGenJnlLine."Transaction No." := vTransactionNo;
        rGenJnlLine."Journal Template Name" := vTemplName;
        rGenJnlLine."Journal Batch Name" := vBatchName;
        rGenJnlLine."Posting Date" := vPostingDate;
        rGenJnlLine."Source Code" := vSourceCode;
        rGenJnlLine."Reason Code" := vReasonCode;
    end;

    local procedure fInsertGenJnlLine(AccountType2: Enum "Gen. Journal Account Type"; AccountNo2: Code[20]; DocumentType2: Enum "Gen. Journal Document Type"; Amount2: Decimal; Amount2LCY: Decimal; Description2: Text[250]; DocNo2: Code[20])
    var
        PreservedDueDate: Date;
        PreservedPaymentMethodCode: Code[10];
    begin
        rGenJnlLine."Account Type" := AccountType2;
        PreservedDueDate := rGenJnlLine."Due Date";
        PreservedPaymentMethodCode := rGenJnlLine."Payment Method Code";
        rGenJnlLine.VALIDATE("Account No.", AccountNo2);
        rGenJnlLine."Due Date" := PreservedDueDate;
        rGenJnlLine."Payment Method Code" := PreservedPaymentMethodCode;
        rGenJnlLine."Document Type" := DocumentType2;
        rGenJnlLine."Document No." := CustLedgEntry."Document No.";
        rGenJnlLine.Description := COPYSTR(Description2, 1, MAXSTRLEN(rGenJnlLine.Description));
        rGenJnlLine.VALIDATE("Currency Code", CustLedgEntry."Currency Code");
        rGenJnlLine.VALIDATE(Amount, Amount2);
        rGenJnlLine.VALIDATE("Amount (LCY)", Amount2LCY);
        rGenJnlLine."Dimension Set ID" := rGenJnlLine."Dimension Set ID";
        rGenJnlLine."Doubful Debt Unprovision" := TRUE;
        rGenJnlLine."Initial Doub. Debt Entry No." := CustLedgEntry."Initial Doub. Debt Entry No.";
        rGenJnlLine."Last Doub. Debt Entry No." := CustLedgEntry."Entry No.";
        rGenJnlLine.INSERT;

    end;

    local procedure fBatchNameOnAfterValidate()

    begin
        IF vTemplName = '' THEN
            vBatchName := '';
    end;

    local procedure fBatchNameOnValidate()

    begin
        IF vBatchName = '' THEN
            EXIT;
    end;
}