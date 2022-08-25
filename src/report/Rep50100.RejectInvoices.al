report 50100 "Reject Invoices"
{
    Caption = 'Impagar documentos';
    UsageCategory = Administration;
    ProcessingOnly = true;
    ApplicationArea = All;
    Permissions = TableData "Cust. Ledger Entry" = imd, TableData "Vendor Ledger Entry" = imd, TableData "Cartera Doc." = imd, TableData "Posted Cartera Doc." = imd, TableData "Closed Cartera Doc." = imd, TableData "Posted Bill Group" = imd, TableData "Closed Bill Group" = imd;

    dataset
    {
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            DataItemTableView = SORTING("Entry No.") WHERE(Open = CONST(true));

            trigger OnPreDataItem()
            begin
                IF vUseJournal = vUseJournal::AuxJournal THEN BEGIN
                    rGenJnlBatch.GET(vTemplName, vBatchName);
                    vReasonCode := rGenJnlBatch."Reason Code";
                    rGenJnlTemplate.GET(vTemplName);
                    vSourceCode := rGenJnlTemplate."Source Code";
                END ELSE BEGIN
                    vReasonCode := '';
                    rSourceCodeSetup.GET;
                    vSourceCode := rSourceCodeSetup."Cartera Journal"
                END;

                Window.OPEN(Text51001);
                vDocCount := 0;
                vGenJnlLineNextNo := 0;
                vExistVATEntry := FALSE;
            end;

            trigger OnAfterGetRecord()
            begin
                vDocCount := vDocCount + 1;
                Window.UPDATE(1, vDocCount);
                CALCFIELDS("Remaining Amount", "Remaining Amt. (LCY)");
                vCurrDescription := STRSUBSTNO(Text51002, "Document No.");
                vCurrDocNo := "Document No.";
                fPrepareInvoiceRejPosting("Remaining Amount");
            end;

            trigger OnPostDataItem()
            begin
                fPostGenJournal;
                COMMIT;
                MESSAGE(Text51003, vDocCount);
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

                    field(vUseJournal; vUseJournal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Journal', comment = 'ESP="Registro"';
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
                                IF vTemplName = '' THEN
                                    vBatchName := '';
                            end;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                IF vTemplName = '' THEN
                                    EXIT;

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

    begin
        rGLSetup.GET;

        IF vUseJournal = vUseJournal::AuxJournal THEN BEGIN
            IF NOT rGenJnlBatch.GET(vTemplName, vBatchName) THEN
                ERROR(Text51000);
            vReasonCode := rGenJnlBatch."Reason Code";
            rGenJnlTemplate.GET(vTemplName);
            vSourceCode := rGenJnlTemplate."Source Code";
        END;
    end;

    var
        rGenJnlTemplate: Record "Gen. Journal Template";
        rGenJnlBatch: record "Gen. Journal Batch";
        rBankAcc: Record "Bank Account";
        rGenJnlLine: Record "Gen. Journal Line" temporary;
        rSourceCodeSetup: Record "Source Code Setup";
        rCustPostingGr: record "Customer Posting Group";
        rBankAccPostingGr: record "Bank Account Posting Group";
        rGLSetup: Record "General Ledger Setup";
        rGLReg: Record "G/L Register";
        rCurrency: Record Currency;
        cGenJnlManagement: Codeunit GenJnlManagement;
        pGeneralJnlForm: page "Del Doubtful Debt Journal";

        Window: Dialog;
        vPostingDate: Date;
        vPostingDate2: Date;
        vTransactionNo: Integer;
        vCurrDescription: Text[250];
        vCurrDocNo: Code[20];
        vCurrDocNo2: Code[20];
        vUseJournal: Enum UseJournal;
        vBatchName: code[10];
        vTemplName: Code[10];
        vSourceCode: Code[10];
        vExistVATEntry: Boolean;
        vReasonCode: Code[10];
        vDocCount: Integer;
        vGenJnlLineNextNo: Integer;

        // Label / TextConstants

        Text51000: Label 'Rellene el nombre del libro y la sección del diario con los valores apropiados.';
        Text51001: Label 'Dotando facturas a cobrar             #1######';
        Text51002: Label 'Documento dotado %1';
        Text51003: Label 'Se ha/n dotado %1 documento/s.';
        Text51004: Label 'Este campo debe estar en blanco para registro directo.';




    local procedure fInsertGenJournalLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount2: Decimal; DimSetID: Integer; pIsDoubtfulDebtAccount: Boolean)


    begin
        vGenJnlLineNextNo := vGenJnlLineNextNo + 10000;
        CLEAR(rGenJnlLine);
        rGenJnlLine.INIT;
        rGenJnlLine."Line No." := vGenJnlLineNextNo;
        rGenJnlLine."Posting Date" := vPostingDate;
        IF vUseJournal = vUseJournal::AuxJournal THEN BEGIN
            rGenJnlLine."Journal Template Name" := vTemplName;
            rGenJnlLine."Journal Batch Name" := vBatchName;

        END;
        rGenJnlLine."Document No." := vCurrDocNo;
        rGenJnlLine."Bill No." := vCurrDocNo2;
        rGenJnlLine.VALIDATE("Account Type", AccType);
        rGenJnlLine.VALIDATE("Account No.", AccNo);
        rGenJnlLine.Description := COPYSTR(vCurrDescription, 1, MAXSTRLEN(rGenJnlLine.Description));
        rGenJnlLine.VALIDATE("Currency Code", "Cust. Ledger Entry"."Currency Code");
        rGenJnlLine.VALIDATE(Amount, Amount2);
        IF AccType = rGenJnlLine."Account Type"::"G/L Account" THEN BEGIN
            rGenJnlLine."Source No." := "Cust. Ledger Entry"."Customer No.";
            rGenJnlLine."Source Type" := rGenJnlLine."Source Type"::Customer;
        END;
        rGenJnlLine."Source Code" := vSourceCode;
        rGenJnlLine."Reason Code" := vReasonCode;
        rGenJnlLine."Dimension Set ID" := DimSetID;
        IF vUseJournal = vUseJournal::AuxJournal THEN
            rGenJnlLine."System-Created Entry" := FALSE
        ELSE
            rGenJnlLine."System-Created Entry" := TRUE;
        rGenJnlLine."Doubtful Debt Provision" := TRUE;
        IF "Cust. Ledger Entry"."Document Type" = "Cust. Ledger Entry"."Document Type"::Invoice THEN BEGIN
            rGenJnlLine."Initial Doub. Debt Entry No." := "Cust. Ledger Entry"."Entry No.";
            rGenJnlLine."Last Doub. Debt Entry No." := "Cust. Ledger Entry"."Entry No.";
        END ELSE BEGIN
            rGenJnlLine."Initial Doub. Debt Entry No." := "Cust. Ledger Entry"."Entry No.";
            rGenJnlLine."Last Doub. Debt Entry No." := "Cust. Ledger Entry"."Entry No.";
        END;
        IF pIsDoubtfulDebtAccount THEN BEGIN
            rGenJnlLine."Doubfutl Debt Account" := TRUE;
        END ELSE BEGIN
            IF (rGenJnlLine."Account Type" = rGenJnlLine."Account Type"::Customer) THEN BEGIN
                "Cust. Ledger Entry"."Applies-to ID" := FORMAT("Cust. Ledger Entry"."Entry No.");
                "Cust. Ledger Entry"."Amount to Apply" := -rGenJnlLine.Amount;
                "Cust. Ledger Entry".MODIFY;
                rGenJnlLine."Applies-to ID" := FORMAT("Cust. Ledger Entry"."Entry No.");
            END;
        END;
        rGenJnlLine.INSERT;
    END;






    local procedure fPrepareInvoiceRejPosting(RemainingAmt: Decimal)

    begin
        rCustPostingGr.GET("Cust. Ledger Entry"."Customer Posting Group");
        rCustPostingGr.TESTFIELD("Late payment account");
        rCustPostingGr.TESTFIELD("Late payment damage account");
        rCustPostingGr.TESTFIELD("Doubtful debts account");
        rCustPostingGr.TESTFIELD("Receivables Account");


        fInsertGenJournalLine(
      rGenJnlLine."Account Type"::Customer,
      "Cust. Ledger Entry"."Customer No.",
      -RemainingAmt,
      "Cust. Ledger Entry"."Dimension Set ID",
      FALSE);

        fInsertGenJournalLine(
          rGenJnlLine."Account Type"::Customer,
          "Cust. Ledger Entry"."Customer No.",
          RemainingAmt,
          "Cust. Ledger Entry"."Dimension Set ID",
          TRUE);

        fInsertGenJournalLine(
          rGenJnlLine."Account Type"::"G/L Account",
          rCustPostingGr."Late payment account",
          RemainingAmt,
          "Cust. Ledger Entry"."Dimension Set ID",
          FALSE);

        fInsertGenJournalLine(
          rGenJnlLine."Account Type"::"G/L Account",
          rCustPostingGr."Late payment damage account",
          -RemainingAmt,
          "Cust. Ledger Entry"."Dimension Set ID",
          FALSE);

    end;

    local procedure fPostGenJournal()
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlLine2: Record "Gen. Journal Line";
        LastLineNo: Integer;

    begin
        Window.CLOSE;

        IF NOT rGenJnlLine.FIND('-') THEN
            EXIT;

        IF vUseJournal = vUseJournal::AuxJournal THEN BEGIN
            GenJnlLine2.LOCKTABLE;
            GenJnlLine2.SETRANGE("Journal Template Name", vTemplName);
            GenJnlLine2.SETRANGE("Journal Batch Name", vBatchName);
            IF GenJnlLine2.FINDLAST THEN BEGIN
                LastLineNo := GenJnlLine2."Line No.";
                vTransactionNo := GenJnlLine2."Transaction No." + 1;
            END;
            REPEAT
                GenJnlLine2 := rGenJnlLine;
                GenJnlLine2."Line No." := GenJnlLine2."Line No." + LastLineNo;
                GenJnlLine2."Transaction No." := vTransactionNo;
                GenJnlLine2.INSERT;
            UNTIL rGenJnlLine.NEXT = 0;
            COMMIT;
            GenJnlLine2.RESET;
            rGenJnlTemplate.GET(vTemplName);
            GenJnlLine2.FILTERGROUP := 2;
            GenJnlLine2.SETRANGE("Journal Template Name", vTemplName);
            GenJnlLine2.FILTERGROUP := 0;
            cGenJnlManagement.SetName(vBatchName, GenJnlLine2);
            pGeneralJnlForm.SETTABLEVIEW(GenJnlLine2);
            pGeneralJnlForm.SETRECORD(GenJnlLine2);
            pGeneralJnlForm.AllowClosing(TRUE);
            pGeneralJnlForm.RUNMODAL;
        END
        ELSE
            REPEAT
                GenJnlLine2 := rGenJnlLine;
                GenJnlPostLine.RunWithCheck(GenJnlLine2);
            UNTIL rGenJnlLine.NEXT = 0;
    end;


}