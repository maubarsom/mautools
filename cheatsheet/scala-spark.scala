import org.apacha.spark.sql.functions._
import spark.implicits._

// Load dataset
spark.read.format("parquet").load("PATH/TO/PARQUET")

//Write dataframe
df.write.format("parquet").mode("overwrite").save("PATH/TO/PARQUET")