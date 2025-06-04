data <- read.csv("C:/Users/computername/Downloads/healthcare_dataset.csv")



# Make names SQL-safe and unique
names(data) <- make.names(names(data), unique = TRUE)

# Create the SQL code
sql_cols <- paste(sprintf('"%s" TEXT', names(data)), collapse = ",\n  ")
create_sql <- sprintf("CREATE TABLE hospital_capacity (\n  %s\n);", sql_cols)

# Print it so you can copy-paste into pgAdmin
cat(create_sql)
