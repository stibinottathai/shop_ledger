-- Add foreign key for customer_id
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_customers
FOREIGN KEY (customer_id)
REFERENCES customers(id)
ON DELETE SET NULL;

-- Add foreign key for supplier_id
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_suppliers
FOREIGN KEY (supplier_id)
REFERENCES suppliers(id)
ON DELETE SET NULL;

-- Verify relationships for PostgREST
-- PostgREST should automatically detect these FKs and allow embedding resources.
