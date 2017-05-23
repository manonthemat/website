defmodule SignDict.Email do
  use Bamboo.Phoenix, view: SignDict.EmailView

  import SignDict.Gettext

  alias SignDict.User
  alias SignDict.Repo

  def contact_form(email, content) do
    base_email()
    |> to({"Bodo", "mail@signdict.org"})
    |> subject("[signdict] " <> gettext("New message via contact form"))
    |> assign(:email, email)
    |> assign(:content, content)
    |> render(:contact_form)
  end

  def confirm_email(user) do
    user
    |> User.confirm_sent_at_changeset
    |> Repo.update

    base_email()
    |> to(user)
    |> subject(gettext("Please confirm your email address"))
    |> assign(:user, user)
    |> render(String.to_atom("confirm_email_#{Gettext.get_locale(SignDict.Gettext)}"))
  end

  def confirm_email_change(user) do
    user
    |> User.confirm_sent_at_changeset
    |> Repo.update

    base_email()
    |> to(user)
    |> subject(gettext("Please confirm the change of your email address"))
    |> assign(:user, user)
    |> render(String.to_atom("confirm_email_change_#{Gettext.get_locale(SignDict.Gettext)}"))
  end

  def password_reset(user) do
    base_email()
    |> to(user)
    |> subject(gettext("Your password reset link"))
    |> assign(:user, user)
    |> render(String.to_atom("password_reset_#{Gettext.get_locale(SignDict.Gettext)}"))
  end

  defp base_email do
    new_email()
    |> from("mail@signdict.org")
    |> put_html_layout({SignDict.LayoutView, "email.html"})
  end
end

defimpl Bamboo.Formatter, for: SignDict.User do
  def format_email_address(user, _opts) do
    {user.name, user.unconfirmed_email || user.email}
  end
end
