import org.apache.ofbiz.entity.util.EntityQuery
import org.apache.ofbiz.service.ServiceUtil

// ── Execute findCustomer ────────────────────────────────────────────────────
def searchParams = [userLogin: userLogin]
if (parameters.partyId)       searchParams.partyId       = parameters.partyId
if (parameters.firstName)     searchParams.firstName     = parameters.firstName
if (parameters.lastName)      searchParams.lastName      = parameters.lastName
if (parameters.emailAddress)  searchParams.emailAddress  = parameters.emailAddress
if (parameters.contactNumber) searchParams.contactNumber = parameters.contactNumber
if (parameters.address)       searchParams.address       = parameters.address

def result      = dispatcher.runSync("findCustomer", searchParams)
def allCustomers = (ServiceUtil.isSuccess(result) ? result.customerList : []) ?: []

// ── Lookup data for relationship modals ────────────────────────────────────
context.partyRelationshipTypes = EntityQuery.use(delegator).from("PartyRelationshipType")
    .orderBy("description").queryList()

// ── Pagination ─────────────────────────────────────────────────────────────
int pageSize   = parameters.pageSize  ? parameters.pageSize.toInteger()  : 10
int pageIndex  = parameters.pageIndex ? parameters.pageIndex.toInteger() : 0
int totalCount = allCustomers.size()
int totalPages = totalCount > 0 ? (int) Math.ceil((double) totalCount / pageSize) : 1
int start      = pageIndex * pageSize
int end        = Math.min(start + pageSize, totalCount)

context.customerList = start < totalCount ? allCustomers.subList(start, end) : []
context.totalCount   = totalCount
context.totalPages   = totalPages
context.pageIndex    = pageIndex
context.pageSize     = pageSize
