import org.apache.ofbiz.entity.util.EntityQuery
import org.apache.ofbiz.service.ServiceUtil

// ── Lookup data for dropdowns ──────────────────────────────────────────────
context.productCategoryList    = EntityQuery.use(delegator).from("ProductCategory")
    .orderBy("categoryName").queryList()

context.productFeatureTypeList = EntityQuery.use(delegator).from("ProductFeatureType")
    .orderBy("description").queryList()

context.allProductFeatures     = EntityQuery.use(delegator).from("ProductFeature")
    .orderBy("description").queryList()

context.virtualProducts        = EntityQuery.use(delegator).from("Product")
    .where("isVirtual", "Y").orderBy("internalName").queryList()

// ── Execute findProduct ────────────────────────────────────────────────────
def searchParams = [userLogin: userLogin]
if (parameters.productId)            searchParams.productId            = parameters.productId
if (parameters.productName)          searchParams.productName          = parameters.productName
if (parameters.priceMin)             searchParams.priceMin             = new BigDecimal(parameters.priceMin)
if (parameters.priceMax)             searchParams.priceMax             = new BigDecimal(parameters.priceMax)
if (parameters.productFeatureTypeId) searchParams.productFeatureTypeId = parameters.productFeatureTypeId
if (parameters.productCategoryId)    searchParams.productCategoryId    = parameters.productCategoryId

def result      = dispatcher.runSync("findProduct", searchParams)
def allProducts = (ServiceUtil.isSuccess(result) ? result.productList : []) ?: []

// ── Pagination ─────────────────────────────────────────────────────────────
int pageSize  = parameters.pageSize  ? parameters.pageSize.toInteger()  : 10
int pageIndex = parameters.pageIndex ? parameters.pageIndex.toInteger() : 0
int totalCount = allProducts.size()
int totalPages = totalCount > 0 ? (int) Math.ceil((double) totalCount / pageSize) : 1
int start      = pageIndex * pageSize
int end        = Math.min(start + pageSize, totalCount)

context.productList = start < totalCount ? allProducts.subList(start, end) : []
context.totalCount  = totalCount
context.totalPages  = totalPages
context.pageIndex   = pageIndex
context.pageSize    = pageSize
