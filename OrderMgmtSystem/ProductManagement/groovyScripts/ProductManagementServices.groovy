import org.apache.ofbiz.entity.util.EntityQuery
import org.apache.ofbiz.entity.condition.EntityCondition
import org.apache.ofbiz.entity.condition.EntityOperator
import org.apache.ofbiz.base.util.UtilDateTime
import org.apache.ofbiz.service.ServiceUtil

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 – findProduct
// Searches FindProductView with optional filters.  Because the outer-join view
// can return multiple rows per product (one per price × feature combination),
// results are deduplicated by productId using a LinkedHashSet.
// ─────────────────────────────────────────────────────────────────────────────
def findProduct() {
    def condList = []

    if (context.productId) {
        condList.add(EntityCondition.makeCondition("productId", EntityOperator.EQUALS, context.productId))
    }
    if (context.productName) {
        condList.add(EntityCondition.makeCondition("productName", EntityOperator.LIKE,
            "%" + context.productName + "%"))
    }
    if (context.priceMin != null) {
        condList.add(EntityCondition.makeCondition("productPriceTypeId", EntityOperator.EQUALS, "LIST_PRICE"))
        condList.add(EntityCondition.makeCondition("price", EntityOperator.GREATER_THAN_EQUAL_TO, context.priceMin))
    }
    if (context.priceMax != null) {
        condList.add(EntityCondition.makeCondition("productPriceTypeId", EntityOperator.EQUALS, "LIST_PRICE"))
        condList.add(EntityCondition.makeCondition("price", EntityOperator.LESS_THAN_EQUAL_TO, context.priceMax))
    }
    if (context.productFeatureTypeId) {
        condList.add(EntityCondition.makeCondition("productFeatureTypeId", EntityOperator.EQUALS, context.productFeatureTypeId))
    }
    if (context.productCategoryId) {
        condList.add(EntityCondition.makeCondition("productCategoryId", EntityOperator.EQUALS, context.productCategoryId))
    }

    def ef = EntityQuery.use(delegator).from("FindProductView")
    if (condList) {
        ef.where(EntityCondition.makeCondition(condList, EntityOperator.AND))
    }
    def rawList = ef.queryList()

    def seen = new LinkedHashSet<String>()
    def productList = []
    for (row in rawList) {
        if (seen.add(row.getString("productId"))) {
            productList.add(row)
        }
    }

    return [productList: productList]
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5a – createProduct
// Enforces unique product name by delegating to findProduct.
// Creates the Product, one ProductCategoryMember, and one LIST_PRICE record.
// ─────────────────────────────────────────────────────────────────────────────
def createProduct() {
    // Uniqueness check via findProduct
    def checkResult = dispatcher.runSync("findProduct",
        [productName: context.productName, userLogin: userLogin])
    if (ServiceUtil.isSuccess(checkResult) && checkResult.productList) {
        return ServiceUtil.returnError("A product named '${context.productName}' already exists.")
    }

    // Validate category
    def category = EntityQuery.use(delegator).from("ProductCategory")
        .where("productCategoryId", context.productCategoryId).queryOne()
    if (!category) {
        return ServiceUtil.returnError("Category '${context.productCategoryId}' does not exist.")
    }

    String productId = delegator.getNextSeqId("Product")

    def product = delegator.makeValue("Product")
    product.set("productId",     productId)
    product.set("productTypeId", "FINISHED_GOOD")
    product.set("internalName",  context.productName)
    if (context.description) product.set("description", context.description)
    delegator.create(product)

    // Category membership
    def catMember = delegator.makeValue("ProductCategoryMember")
    catMember.set("productCategoryId", context.productCategoryId)
    catMember.set("productId",         productId)
    catMember.set("fromDate",          UtilDateTime.nowTimestamp())
    delegator.create(catMember)

    // List price
    def priceRec = delegator.makeValue("ProductPrice")
    priceRec.set("productId",             productId)
    priceRec.set("productPriceTypeId",    "LIST_PRICE")
    priceRec.set("productPricePurposeId", "PURCHASE")
    priceRec.set("currencyUomId",         "USD")
    priceRec.set("productStoreGroupId",   "_NA_")
    priceRec.set("fromDate",              UtilDateTime.nowTimestamp())
    priceRec.set("price",                 context.price)
    delegator.create(priceRec)

    return [productId: productId]
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5b – updateProduct
// Validates the product exists, then updates name/description, price, and/or
// applies a feature (idempotent: skips if already applied).
// ─────────────────────────────────────────────────────────────────────────────
def updateProduct() {
    def product = EntityQuery.use(delegator).from("Product")
        .where("productId", context.productId).queryOne()
    if (!product) {
        return ServiceUtil.returnError("Product '${context.productId}' does not exist.")
    }

    boolean dirty = false
    if (context.productName)  { product.set("internalName", context.productName); dirty = true }
    if (context.description)  { product.set("description",  context.description);  dirty = true }
    if (dirty) product.store()

    if (context.price != null) {
        def existing = EntityQuery.use(delegator).from("ProductPrice")
            .where("productId",             context.productId,
                   "productPriceTypeId",    "LIST_PRICE",
                   "productPricePurposeId", "PURCHASE",
                   "currencyUomId",         "USD",
                   "productStoreGroupId",   "_NA_")
            .filterByDate().queryFirst()
        if (existing) {
            existing.set("price", context.price)
            existing.store()
        } else {
            def newPrice = delegator.makeValue("ProductPrice")
            newPrice.set("productId",             context.productId)
            newPrice.set("productPriceTypeId",    "LIST_PRICE")
            newPrice.set("productPricePurposeId", "PURCHASE")
            newPrice.set("currencyUomId",         "USD")
            newPrice.set("productStoreGroupId",   "_NA_")
            newPrice.set("fromDate",              UtilDateTime.nowTimestamp())
            newPrice.set("price",                 context.price)
            delegator.create(newPrice)
        }
    }

    if (context.productFeatureId) {
        def applExists = EntityQuery.use(delegator).from("ProductFeatureAppl")
            .where("productId", context.productId, "productFeatureId", context.productFeatureId)
            .filterByDate().queryFirst()
        if (!applExists) {
            def appl = delegator.makeValue("ProductFeatureAppl")
            appl.set("productId",               context.productId)
            appl.set("productFeatureId",        context.productFeatureId)
            appl.set("fromDate",                UtilDateTime.nowTimestamp())
            appl.set("productFeatureApplTypeId","STANDARD_FEATURE")
            delegator.create(appl)
        }
    }

    return ServiceUtil.returnSuccess()
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 6a – assocProductToVirtual
// Creates a PRODUCT_VARIANT ProductAssoc from virtualProductId → productId.
// Validates both products exist and no active duplicate association exists.
// ─────────────────────────────────────────────────────────────────────────────
def assocProductToVirtual() {
    def product = EntityQuery.use(delegator).from("Product")
        .where("productId", context.productId).queryOne()
    if (!product) {
        return ServiceUtil.returnError("Product '${context.productId}' does not exist.")
    }

    def virtualProduct = EntityQuery.use(delegator).from("Product")
        .where("productId", context.virtualProductId).queryOne()
    if (!virtualProduct) {
        return ServiceUtil.returnError("Virtual product '${context.virtualProductId}' does not exist.")
    }

    def existing = EntityQuery.use(delegator).from("ProductAssoc")
        .where("productId",          context.virtualProductId,
               "productIdTo",        context.productId,
               "productAssocTypeId", "PRODUCT_VARIANT")
        .filterByDate().queryFirst()
    if (existing) {
        return ServiceUtil.returnError("A PRODUCT_VARIANT association between these products already exists.")
    }

    def assoc = delegator.makeValue("ProductAssoc")
    assoc.set("productId",          context.virtualProductId)
    assoc.set("productIdTo",        context.productId)
    assoc.set("productAssocTypeId", "PRODUCT_VARIANT")
    assoc.set("fromDate",           UtilDateTime.nowTimestamp())
    delegator.create(assoc)

    return ServiceUtil.returnSuccess()
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 6b – updateProductVariant
// Finds the active PRODUCT_VARIANT assoc and either:
//   • sets its thruDate, or
//   • expires it and creates a new assoc pointing to newVirtualProductId
// ─────────────────────────────────────────────────────────────────────────────
def updateProductVariant() {
    def assoc = EntityQuery.use(delegator).from("ProductAssoc")
        .where("productId",          context.virtualProductId,
               "productIdTo",        context.productId,
               "productAssocTypeId", "PRODUCT_VARIANT")
        .filterByDate().queryFirst()
    if (!assoc) {
        return ServiceUtil.returnError(
            "No active PRODUCT_VARIANT association found between '${context.virtualProductId}' and '${context.productId}'.")
    }

    if (context.thruDate) {
        assoc.set("thruDate", context.thruDate)
        assoc.store()
    }

    if (context.newVirtualProductId) {
        def newVirtual = EntityQuery.use(delegator).from("Product")
            .where("productId", context.newVirtualProductId).queryOne()
        if (!newVirtual) {
            return ServiceUtil.returnError("New virtual product '${context.newVirtualProductId}' does not exist.")
        }

        // Expire the existing assoc
        assoc.set("thruDate", UtilDateTime.nowTimestamp())
        assoc.store()

        // Create replacement assoc
        def newAssoc = delegator.makeValue("ProductAssoc")
        newAssoc.set("productId",          context.newVirtualProductId)
        newAssoc.set("productIdTo",        context.productId)
        newAssoc.set("productAssocTypeId", "PRODUCT_VARIANT")
        newAssoc.set("fromDate",           UtilDateTime.nowTimestamp())
        delegator.create(newAssoc)
    }

    return ServiceUtil.returnSuccess()
}
