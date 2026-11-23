class UsdAmount
  class Invalid < StandardError; end

  MAX = BigDecimal("99999999999999999.99")

  def self.parse(text)
    # Validate before Active Record casts the value. This rejects numbers sent
    # as JSON floats and extra decimal places that PostgreSQL would round.
    unless text.is_a?(String) && /\A[0-9]{1,17}(?:\.[0-9]{1,2})?\z/.match?(text)
      raise Invalid, "Enter a decimal amount with up to 17 whole digits and two decimal places."
    end

    BigDecimal(text)
  end

  # A JSON string carries every digit. Formatting via to_f could lose cents
  # at large balances. SUM also returns an exact decimal from PostgreSQL.
  def self.as_json_string(decimal)
    whole, cents = decimal.to_s("F").split(".", 2)
    "#{whole}.#{cents.to_s.ljust(2, "0")}"
  end
end
