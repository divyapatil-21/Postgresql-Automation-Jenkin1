import pandas as pd
from db_connection import get_connection


def load_orders(csv_file):

    dataframe = pd.read_csv(csv_file)

    connection = get_connection()
    cursor     = connection.cursor()
    inserted   = 0

    for _, row in dataframe.iterrows():

        cursor.execute(
            """
            INSERT INTO orders
            (order_id, customer_id, product_id, quantity, order_date)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (
                row["order_id"],
                row["customer_id"],
                row["product_id"],
                row["quantity"],
                row["order_date"]
            )
        )

        inserted += 1

    connection.commit()
    cursor.close()
    connection.close()

    print(f"Orders Loaded : {inserted}")


if __name__ == "__main__":
    print("Use from load_all.py")
