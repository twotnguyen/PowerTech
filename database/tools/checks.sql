.headers on
.mode column
.print '== C1 Products.StockQuantity vs sum(IMPORT)-sum(EXPORT) (mismatches)'
select p.Id, p.SKU, p.StockQuantity as stock, coalesce(t.net,0) as txn_net, p.StockQuantity-coalesce(t.net,0) as diff
from Products p left join (select ProductId, sum(case TransactionType when 'IMPORT' then Quantity else -Quantity end) net from StockTransactions group by 1) t on t.ProductId=p.Id
where p.StockQuantity<>coalesce(t.net,0) order by abs(diff) desc limit 15;
.print '== C1b count mismatches'
select count(*) n from Products p left join (select ProductId, sum(case TransactionType when 'IMPORT' then Quantity else -Quantity end) net from StockTransactions group by 1) t on t.ProductId=p.Id where p.StockQuantity<>coalesce(t.net,0);
.print '== C2 StockTransactions: Before +/- Quantity = After'
select count(*) bad from StockTransactions where AfterQuantity <> BeforeQuantity + case TransactionType when 'IMPORT' then Quantity else -Quantity end;
.print '== C3 per-product chain continuity (Before = previous After, ordered by CreatedAt,Id)'
with o as (select *, lag(AfterQuantity) over (partition by ProductId order by CreatedAt, Id) prev from StockTransactions)
select count(*) bad from o where (prev is null and BeforeQuantity<>0) or (prev is not null and prev<>BeforeQuantity);
.print '== C3b last After vs Products.StockQuantity'
with l as (select ProductId, AfterQuantity a, row_number() over (partition by ProductId order by CreatedAt desc, Id desc) rn from StockTransactions)
select count(*) bad from l join Products p on p.Id=l.ProductId where rn=1 and p.StockQuantity<>a;
.print '== C4 products with no stock transactions'
select count(*) n, sum(StockQuantity) stock from Products p where not exists(select 1 from StockTransactions t where t.ProductId=p.Id);
.print '== C5 SoldQuantity vs sum(OrderItems.Quantity) by order status'
select p.Id, p.SKU, p.SoldQuantity sold,
 coalesce(sum(case when o.OrderStatus='Completed' then i.Quantity end),0) completed_qty,
 coalesce(sum(case when o.OrderStatus not in ('Cancelled','Returned') then i.Quantity end),0) active_qty,
 coalesce(sum(i.Quantity),0) all_qty
from Products p left join OrderItems i on i.ProductId=p.Id left join Orders o on o.Id=i.OrderId
group by p.Id having p.SoldQuantity<>completed_qty order by p.Id limit 25;
.print '== C5b counts: mismatch vs completed / vs active / vs all'
with x as (select p.Id, p.SoldQuantity sold,
 coalesce(sum(case when o.OrderStatus='Completed' then i.Quantity end),0) c,
 coalesce(sum(case when o.OrderStatus not in ('Cancelled','Returned') then i.Quantity end),0) a,
 coalesce(sum(i.Quantity),0) al
from Products p left join OrderItems i on i.ProductId=p.Id left join Orders o on o.Id=i.OrderId group by p.Id)
select sum(sold<>c) vs_completed, sum(sold<>a) vs_active, sum(sold<>al) vs_all, sum(sold>0) products_with_sold from x;
.print '== C6 EXPORT transactions vs OrderItems (ReferenceType values)'
select ReferenceType, count(*), sum(Quantity) from StockTransactions where TransactionType='EXPORT' group by 1;
select 'order_items_total_qty', sum(Quantity) from OrderItems;
select 'sum SoldQuantity', sum(SoldQuantity) from Products;
.print '== C7 Orders.Subtotal vs sum(OrderItems.LineTotal)'
select o.Id, o.OrderCode, o.OrderStatus, o.Subtotal, coalesce(s,0) items_total from Orders o left join (select OrderId, sum(LineTotal) s from OrderItems group by 1) i on i.OrderId=o.Id where o.Subtotal<>coalesce(s,0);
.print '== C8 Orders without items'
select count(*) from Orders o where not exists (select 1 from OrderItems i where i.OrderId=o.Id);
.print '== C9 Payment status vs order status'
select OrderStatus, PaymentStatus, PaymentMethod, count(*) from Orders group by 1,2,3;
.print '== C10 Order last history status vs OrderStatus'
with h as (select OrderId, Status, row_number() over (partition by OrderId order by CreatedAt desc, Id desc) rn from OrderHistory)
select o.Id, o.OrderCode, o.OrderStatus, h.Status hist from Orders o left join h on h.OrderId=o.Id and rn=1 where h.Status is null or h.Status<>o.OrderStatus limit 40;
.print '== C11 Coupons.UsedCount vs orders using coupon'
select c.Id, c.Code, c.UsedCount, (select count(*) from Orders o where o.CouponId=c.Id) orders_using from Coupons c;
.print '== C12 PurchaseReceipts totals vs items'
select r.Id, r.ReceiptCode, r.Subtotal, r.TotalAmount, coalesce(s,0) items_total, coalesce(q,0) item_qty from PurchaseReceipts r left join (select PurchaseReceiptId, sum(LineTotal) s, sum(Quantity) q from PurchaseReceiptItems group by 1) i on i.PurchaseReceiptId=r.Id where r.Subtotal<>coalesce(s,0) or r.TotalAmount<>coalesce(s,0);
.print '== C12b receipt item LineTotal=Quantity*ImportPrice'
select count(*) from PurchaseReceiptItems where abs(LineTotal-Quantity*ImportPrice)>0.005;
.print '== C13 PurchaseReceiptItems vs IMPORT stock transactions (per receipt, product)'
select count(*) bad from (select i.PurchaseReceiptId r, i.ProductId p, i.Quantity q, (select coalesce(sum(Quantity),0) from StockTransactions t where t.TransactionType='IMPORT' and t.ReferenceType='PurchaseReceipt' and t.ReferenceId=i.PurchaseReceiptId and t.ProductId=i.ProductId) tq from PurchaseReceiptItems i) where q<>tq;
select count(*) orphan_import_txn from StockTransactions t where t.TransactionType='IMPORT' and not exists(select 1 from PurchaseReceiptItems i where i.PurchaseReceiptId=t.ReferenceId and i.ProductId=t.ProductId);
.print '== C14 Product price sanity / discount'
select count(*) from Products where DiscountPrice is not null and DiscountPrice>Price;
select 'inactive products', count(*) from Products where IsActive=0;
.print '== C15 Thumbnail vs primary image'
select count(*) no_primary from Products p where not exists (select 1 from ProductImages i where i.ProductId=p.Id and i.IsPrimary=1);
select count(*) thumb_mismatch from Products p join ProductImages i on i.ProductId=p.Id and i.IsPrimary=1 where coalesce(p.ThumbnailUrl,'')<>i.ImageUrl;
.print '== C16 ProductSpecifications spec def category vs product category'
select count(*) bad from ProductSpecifications ps join Products p on p.Id=ps.ProductId join SpecificationDefinitions d on d.Id=ps.SpecDefinitionId where d.CategoryId<>p.CategoryId;
.print '== C17 Reviews'
select count(*) from Reviews r where not exists (select 1 from OrderItems i join Orders o on o.Id=i.OrderId where o.UserId=r.UserId and i.ProductId=r.ProductId and o.OrderStatus='Completed');
.print '== C18 Model check: StockQuantity = 100 (opening stock, not in ledger) + IMPORT - EXPORT - SoldQuantity'
with n as (select ProductId, sum(case TransactionType when 'IMPORT' then Quantity else -Quantity end) net from StockTransactions group by 1)
select p.Id, p.SKU, p.StockQuantity stock, coalesce(n.net,0) net, p.SoldQuantity sold, p.StockQuantity-(100+coalesce(n.net,0)-p.SoldQuantity) diff
from Products p left join n on n.ProductId=p.Id where p.StockQuantity<>(100+coalesce(n.net,0)-p.SoldQuantity);
.print '== C19 Cancelled orders: quantity still counted in SoldQuantity'
select count(*) lines, coalesce(sum(i.Quantity),0) qty from OrderItems i join Orders o on o.Id=i.OrderId where o.OrderStatus in ('Cancelled','Returned');
.print '== C20 Orders without any OrderHistory row'
select count(*) from Orders o where not exists(select 1 from OrderHistory h where h.OrderId=o.Id);
.print '== C21 Products with no ProductImages row'
select count(*) from Products p where not exists(select 1 from ProductImages i where i.ProductId=p.Id);
