class UserJson
  # Share the public identity fields across registration, sign-in, and /api/me.
  # Explicit fields keep credentials out of responses; IDs stay strings.
  def self.call(user)
    {
      id: user.id.to_s,
      name: user.name,
      email: user.email
    }
  end
end
