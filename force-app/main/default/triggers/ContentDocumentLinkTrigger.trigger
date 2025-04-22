trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
  ContentDocumentLinkTriggerHandler.onAfterInsertByStage(Trigger.new);
}
