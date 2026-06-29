import org.apache.ofbiz.entity.util.EntityQuery
import org.apache.ofbiz.entity.condition.EntityCondition
import org.apache.ofbiz.entity.condition.EntityOperator
import org.apache.ofbiz.base.util.UtilDateTime
import org.apache.ofbiz.service.ServiceUtil

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers — resolve contact-mech data for a given partyId
// ─────────────────────────────────────────────────────────────────────────────

private String resolveEmail(String partyId, localDelegator) {
    def purpose = EntityQuery.use(localDelegator).from("PartyContactMechPurpose")
        .where("partyId", partyId, "contactMechPurposeTypeId", "EmailPrimary")
        .filterByDate().queryFirst()
    if (!purpose) return null
    def cm = EntityQuery.use(localDelegator).from("ContactMech")
        .where("contactMechId", purpose.getString("contactMechId")).queryOne()
    return cm?.getString("infoString")
}

private String resolvePhone(String partyId, localDelegator) {
    def purpose = EntityQuery.use(localDelegator).from("PartyContactMechPurpose")
        .where("partyId", partyId, "contactMechPurposeTypeId", "PHONE_HOME")
        .filterByDate().queryFirst()
    if (!purpose) return null
    def tcn = EntityQuery.use(localDelegator).from("TelecomNumber")
        .where("contactMechId", purpose.getString("contactMechId")).queryOne()
    if (!tcn) return null
    String area = tcn.getString("areaCode") ?: ""
    return area.isEmpty() ? tcn.getString("contactNumber") : "${area}-${tcn.getString("contactNumber")}"
}

private Map resolveAddress(String partyId, localDelegator) {
    def purpose = EntityQuery.use(localDelegator).from("PartyContactMechPurpose")
        .where("partyId", partyId, "contactMechPurposeTypeId", "GENERAL_LOCATION")
        .filterByDate().queryFirst()
    if (!purpose) return [:]
    def pa = EntityQuery.use(localDelegator).from("PostalAddress")
        .where("contactMechId", purpose.getString("contactMechId")).queryOne()
    if (!pa) return [:]
    return [
        contactMechId: purpose.getString("contactMechId"),
        address1:      pa.getString("address1"),
        city:          pa.getString("city"),
        postalCode:    pa.getString("postalCode"),
        countryGeoId:  pa.getString("countryGeoId")
    ]
}

private String findPartyIdByEmail(String email, localDelegator) {
    def cm = EntityQuery.use(localDelegator).from("ContactMech")
        .where("infoString", email, "contactMechTypeId", "EMAIL_ADDRESS")
        .queryFirst()
    if (!cm) return null
    def purpose = EntityQuery.use(localDelegator).from("PartyContactMechPurpose")
        .where("contactMechId", cm.getString("contactMechId"),
               "contactMechPurposeTypeId", "EmailPrimary")
        .filterByDate().queryFirst()
    return purpose?.getString("partyId")
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 – findCustomer
// Queries Person for name/partyId filters, then enriches each match with
// primary email, phone, and postal address.  Applies secondary filters
// (email, phone, address) after enrichment.
// ─────────────────────────────────────────────────────────────────────────────
def findCustomer() {
    def condList = []
    if (context.partyId) {
        condList.add(EntityCondition.makeCondition("partyId", EntityOperator.EQUALS, context.partyId))
    }
    if (context.firstName) {
        condList.add(EntityCondition.makeCondition("firstName", EntityOperator.LIKE,
            "%" + context.firstName + "%"))
    }
    if (context.lastName) {
        condList.add(EntityCondition.makeCondition("lastName", EntityOperator.LIKE,
            "%" + context.lastName + "%"))
    }

    def personQuery = EntityQuery.use(delegator).from("Person")
    if (condList) {
        personQuery.where(EntityCondition.makeCondition(condList, EntityOperator.AND))
    }
    def personList = personQuery.queryList()

    def customerList = []

    for (person in personList) {
        String pid = person.getString("partyId")

        String email = resolveEmail(pid, delegator)

        if (context.emailAddress) {
            if (!email || !email.toLowerCase().contains(context.emailAddress.toLowerCase())) continue
        }

        String phone = resolvePhone(pid, delegator)

        if (context.contactNumber) {
            if (!phone || !phone.contains(context.contactNumber)) continue
        }

        def addrMap = resolveAddress(pid, delegator)

        if (context.address) {
            String a1 = addrMap?.address1 ?: ""
            if (!a1.toLowerCase().contains(context.address.toLowerCase())) continue
        }

        customerList.add([
            partyId:      pid,
            firstName:    person.getString("firstName"),
            lastName:     person.getString("lastName"),
            emailAddress: email,
            contactNumber: phone,
            address1:     addrMap?.address1,
            city:         addrMap?.city,
            postalCode:   addrMap?.postalCode,
            countryGeoId: addrMap?.countryGeoId
        ])
    }

    return [customerList: customerList]
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5a – createCustomer
// Enforces email uniqueness via the EmailPrimary contact mech purpose.
// Creates Party → Person → ContactMech (email) → PartyContactMech
// → PartyContactMechPurpose chain.
// ─────────────────────────────────────────────────────────────────────────────
def createCustomer() {
    // Uniqueness check: find ContactMech with this email already tagged EmailPrimary
    def existingCm = EntityQuery.use(delegator).from("ContactMech")
        .where("infoString", context.emailAddress, "contactMechTypeId", "EMAIL_ADDRESS")
        .queryFirst()
    if (existingCm) {
        def existingPurpose = EntityQuery.use(delegator).from("PartyContactMechPurpose")
            .where("contactMechId", existingCm.getString("contactMechId"),
                   "contactMechPurposeTypeId", "EmailPrimary")
            .filterByDate().queryFirst()
        if (existingPurpose) {
            return ServiceUtil.returnError(
                "A customer with email '${context.emailAddress}' already exists.")
        }
    }

    // Create Party
    String partyId = delegator.getNextSeqId("Party")
    def party = delegator.makeValue("Party")
    party.set("partyId",     partyId)
    party.set("partyTypeId", "PERSON")
    delegator.create(party)

    // Create Person
    def person = delegator.makeValue("Person")
    person.set("partyId",   partyId)
    person.set("firstName", context.firstName)
    person.set("lastName",  context.lastName)
    delegator.create(person)

    // Create email ContactMech
    String emailCmId = delegator.getNextSeqId("ContactMech")
    def emailCm = delegator.makeValue("ContactMech")
    emailCm.set("contactMechId",     emailCmId)
    emailCm.set("contactMechTypeId", "EMAIL_ADDRESS")
    emailCm.set("infoString",        context.emailAddress)
    delegator.create(emailCm)

    // Link party to email contact mech
    def pcm = delegator.makeValue("PartyContactMech")
    pcm.set("partyId",       partyId)
    pcm.set("contactMechId", emailCmId)
    pcm.set("fromDate",      UtilDateTime.nowTimestamp())
    delegator.create(pcm)

    // Tag as primary email
    def pcmp = delegator.makeValue("PartyContactMechPurpose")
    pcmp.set("partyId",                  partyId)
    pcmp.set("contactMechId",            emailCmId)
    pcmp.set("contactMechPurposeTypeId", "EmailPrimary")
    pcmp.set("fromDate",                 UtilDateTime.nowTimestamp())
    delegator.create(pcmp)

    return [partyId: partyId]
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5b – updateCustomer
// Identifies the customer by their primary email, then updates or creates
// the PHONE_HOME and/or GENERAL_LOCATION contact mechanisms.
// ─────────────────────────────────────────────────────────────────────────────
def updateCustomer() {
    String partyId = findPartyIdByEmail(context.emailAddress, delegator)
    if (!partyId) {
        return ServiceUtil.returnError(
            "No customer found with primary email '${context.emailAddress}'.")
    }

    // ── Update / create phone ──────────────────────────────────────────────
    if (context.contactNumber) {
        def phonePurpose = EntityQuery.use(delegator).from("PartyContactMechPurpose")
            .where("partyId", partyId, "contactMechPurposeTypeId", "PHONE_HOME")
            .filterByDate().queryFirst()

        if (phonePurpose) {
            def tcn = EntityQuery.use(delegator).from("TelecomNumber")
                .where("contactMechId", phonePurpose.getString("contactMechId")).queryOne()
            if (tcn) {
                tcn.set("contactNumber", context.contactNumber)
                tcn.store()
            }
        } else {
            String phoneCmId = delegator.getNextSeqId("ContactMech")
            def phoneCm = delegator.makeValue("ContactMech")
            phoneCm.set("contactMechId",     phoneCmId)
            phoneCm.set("contactMechTypeId", "TELECOM_NUMBER")
            delegator.create(phoneCm)

            def tcn = delegator.makeValue("TelecomNumber")
            tcn.set("contactMechId",  phoneCmId)
            tcn.set("contactNumber",  context.contactNumber)
            delegator.create(tcn)

            def phonePcm = delegator.makeValue("PartyContactMech")
            phonePcm.set("partyId",       partyId)
            phonePcm.set("contactMechId", phoneCmId)
            phonePcm.set("fromDate",      UtilDateTime.nowTimestamp())
            delegator.create(phonePcm)

            def phonePcmp = delegator.makeValue("PartyContactMechPurpose")
            phonePcmp.set("partyId",                  partyId)
            phonePcmp.set("contactMechId",            phoneCmId)
            phonePcmp.set("contactMechPurposeTypeId", "PHONE_HOME")
            phonePcmp.set("fromDate",                 UtilDateTime.nowTimestamp())
            delegator.create(phonePcmp)
        }
    }

    // ── Update / create postal address ────────────────────────────────────
    if (context.address1 || context.city || context.postalCode || context.countryGeoId) {
        def addrPurpose = EntityQuery.use(delegator).from("PartyContactMechPurpose")
            .where("partyId", partyId, "contactMechPurposeTypeId", "GENERAL_LOCATION")
            .filterByDate().queryFirst()

        if (addrPurpose) {
            def pa = EntityQuery.use(delegator).from("PostalAddress")
                .where("contactMechId", addrPurpose.getString("contactMechId")).queryOne()
            if (pa) {
                if (context.address1)     pa.set("address1",          context.address1)
                if (context.city)         pa.set("city",              context.city)
                if (context.postalCode)   pa.set("postalCode",        context.postalCode)
                if (context.countryGeoId) pa.set("countryGeoId",      context.countryGeoId)
                pa.store()
            }
        } else {
            String addrCmId = delegator.getNextSeqId("ContactMech")
            def addrCm = delegator.makeValue("ContactMech")
            addrCm.set("contactMechId",     addrCmId)
            addrCm.set("contactMechTypeId", "POSTAL_ADDRESS")
            delegator.create(addrCm)

            def pa = delegator.makeValue("PostalAddress")
            pa.set("contactMechId", addrCmId)
            if (context.address1)     pa.set("address1",     context.address1)
            if (context.city)         pa.set("city",         context.city)
            if (context.postalCode)   pa.set("postalCode",   context.postalCode)
            if (context.countryGeoId) pa.set("countryGeoId", context.countryGeoId)
            delegator.create(pa)

            def addrPcm = delegator.makeValue("PartyContactMech")
            addrPcm.set("partyId",       partyId)
            addrPcm.set("contactMechId", addrCmId)
            addrPcm.set("fromDate",      UtilDateTime.nowTimestamp())
            delegator.create(addrPcm)

            def addrPcmp = delegator.makeValue("PartyContactMechPurpose")
            addrPcmp.set("partyId",                  partyId)
            addrPcmp.set("contactMechId",            addrCmId)
            addrPcmp.set("contactMechPurposeTypeId", "GENERAL_LOCATION")
            addrPcmp.set("fromDate",                 UtilDateTime.nowTimestamp())
            delegator.create(addrPcmp)
        }
    }

    return ServiceUtil.returnSuccess()
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 6a – createCustomerRelationship
// Creates a PartyRelationship between two parties.
// roleTypeIdFrom / roleTypeIdTo default to "_NA_" when not supplied.
// Rejects a duplicate active relationship of the same type.
// ─────────────────────────────────────────────────────────────────────────────
def createCustomerRelationship() {
    def partyFrom = EntityQuery.use(delegator).from("Party")
        .where("partyId", context.partyIdFrom).queryOne()
    if (!partyFrom) {
        return ServiceUtil.returnError("Party '${context.partyIdFrom}' does not exist.")
    }

    def partyTo = EntityQuery.use(delegator).from("Party")
        .where("partyId", context.partyIdTo).queryOne()
    if (!partyTo) {
        return ServiceUtil.returnError("Party '${context.partyIdTo}' does not exist.")
    }

    String roleFrom = context.roleTypeIdFrom ?: "_NA_"
    String roleTo   = context.roleTypeIdTo   ?: "_NA_"

    // Prevent duplicate active relationship
    def existing = EntityQuery.use(delegator).from("PartyRelationship")
        .where("partyIdFrom",             context.partyIdFrom,
               "partyIdTo",              context.partyIdTo,
               "roleTypeIdFrom",         roleFrom,
               "roleTypeIdTo",           roleTo,
               "partyRelationshipTypeId", context.partyRelationshipTypeId)
        .filterByDate().queryFirst()
    if (existing) {
        return ServiceUtil.returnError(
            "An active relationship of type '${context.partyRelationshipTypeId}' " +
            "already exists between these parties.")
    }

    def rel = delegator.makeValue("PartyRelationship")
    rel.set("partyIdFrom",             context.partyIdFrom)
    rel.set("partyIdTo",              context.partyIdTo)
    rel.set("roleTypeIdFrom",         roleFrom)
    rel.set("roleTypeIdTo",           roleTo)
    rel.set("partyRelationshipTypeId", context.partyRelationshipTypeId)
    rel.set("fromDate",               UtilDateTime.nowTimestamp())
    if (context.statusId) rel.set("statusId", context.statusId)
    delegator.create(rel)

    return ServiceUtil.returnSuccess()
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 6b – updateCustomerRelationship
// Finds the most recent active PartyRelationship and updates statusId
// and/or thruDate.
// ─────────────────────────────────────────────────────────────────────────────
def updateCustomerRelationship() {
    String roleFrom = context.roleTypeIdFrom ?: "_NA_"
    String roleTo   = context.roleTypeIdTo   ?: "_NA_"

    def rel = EntityQuery.use(delegator).from("PartyRelationship")
        .where("partyIdFrom",             context.partyIdFrom,
               "partyIdTo",              context.partyIdTo,
               "roleTypeIdFrom",         roleFrom,
               "roleTypeIdTo",           roleTo,
               "partyRelationshipTypeId", context.partyRelationshipTypeId)
        .filterByDate().queryFirst()

    if (!rel) {
        return ServiceUtil.returnError(
            "No active relationship of type '${context.partyRelationshipTypeId}' " +
            "found between '${context.partyIdFrom}' and '${context.partyIdTo}'.")
    }

    if (context.statusId)  rel.set("statusId",  context.statusId)
    if (context.thruDate)  rel.set("thruDate",  context.thruDate)
    rel.store()

    return ServiceUtil.returnSuccess()
}
