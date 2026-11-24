class UsdAmount
  class Invalid < StandardError; end

  # Matches PostgreSQL decimal(19, 2), with 17 whole digits and two decimal places.
  MAX = BigDecimal("99999999999999999.99")

  def self.parse(text)
    # Validate the full input before Active Record casts it. The API expects a
    # JSON string and rejects extra decimal places that PostgreSQL would round.
    unless text.is_a?(String) && /\A[0-9]{1,17}(?:\.[0-9]{1,2})?\z/.match?(text)
      raise Invalid, "Enter a decimal amount with up to 17 whole digits and two decimal places."
    end

    BigDecimal(text)
  end

  # BigDecimal#to_s("F") gives plain decimal text. Pad to two decimal places
  # and send the result as a JSON string to preserve every digit.
  def self.as_json_string(decimal)
    whole, cents = decimal.to_s("F").split(".", 2)
    "#{whole}.#{cents.to_s.ljust(2, "0")}"
  end
end
