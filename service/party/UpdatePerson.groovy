import org.moqui.entity.EntityValue

// Validate that partyId is provided
if (!partyId) {
    ec.message.addError("partyId is missing")
    return
}

// Verify that a Person record exists for the given partyId
EntityValue person = ec.entity.find("com.moqui.party.Person").condition("partyId", partyId).one()
if (person == null) {
    ec.message.addError("Person record does not exist for partyId: " + partyId)
    return
}

// Update the fields using the incoming context
// second param is boolean setIfEmpty (usually true, but here if they omit firstName we shouldn't wipe it, wait.. in REST a PUT usually sets to null or ignores)
// Actually setIfEmpty = true is in create. We might want setIfEmpty = false for a partial update? Let's use setIfEmpty = true to follow standard pattern, or just let moqui handle it.
// Oh actually the standard update pattern is setFields(context, true, null, null).
person.setFields(context, true, null, null)

// Update the Person record in the database
person.update()

String responseMsg = "Person ${person.firstName} ${person.lastName} updated successfully!"
ec.message.addMessage(responseMsg)
context.responseString = responseMsg
