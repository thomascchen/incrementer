defmodule Siege.UrlGen do
  def generate do
    rows = Enum.map(
      1..1_000,
      fn(_) -> construct() end
    )

    joined_rows = Enum.join(rows, "\n")

    File.write('./siege/urls.txt', joined_rows)
  end

  defp construct do
    key = Enum.random(1..100)
    value = Enum.random(1..100)

    "http://localhost:3333/increment POST key=#{key}&value=#{value}"
  end
end

Siege.UrlGen.generate()
