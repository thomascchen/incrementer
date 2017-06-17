defmodule Database do
  @moduledoc """
  This module contains functions for interfacing with the database
  """

  @doc """
  Creates a SQLite database named `./numbers.db`, containing the following:

  ```CREATE TABLE numbers (key TEXT, value INTEGER DEFAULT 0);
  CREATE UNIQUE INDEX numbers_key_index ON numbers (key);
  ```

  Returns `:ok`.
  """
  def create do
    {:ok, db} = Sqlitex.open("./numbers.db")

    Sqlitex.exec(db, """
      CREATE TABLE numbers (key TEXT, value INTEGER DEFAULT 0);
      CREATE UNIQUE INDEX numbers_key_index ON numbers (key);
      """)
  end
end
