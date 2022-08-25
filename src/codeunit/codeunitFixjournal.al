codeunit 50101 "Fix Debt Journal"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Template", 'OnAfterValidateType', '', false, false)]
    local procedure OnAfterValidateType(var GenJournalTemplate: Record "Gen. Journal Template"; SourceCodeSetup: Record "Source Code Setup");
    var
        plDelDoubtfulDebtJournal: Page "Del Doubtful Debt Journal";
    begin
        if GenJournalTemplate.Type = GenJournalTemplate.Type::Doubtful then
            GenJournalTemplate."Source Code" := SourceCodeSetup."Cartera Journal";
        GenJournalTemplate."Page ID" := PAGE::"Del Doubtful Debt Journal";
    end;

}