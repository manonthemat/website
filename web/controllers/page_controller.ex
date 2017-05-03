defmodule SignDict.PageController do
  use SignDict.Web, :controller

  def index(conn, _params) do
    human_count = Repo.aggregate(SignDict.User, :count, :id)
    render conn, "index.html", layout: {SignDict.LayoutView, "empty.html"},
      human_count: human_count, sign_count: sign_count()
  end

  def imprint(conn, _params) do
    render conn, "imprint.html", layout: {SignDict.LayoutView, "app.html"},
       title: gettext("Imprint")
  end

  def welcome(conn, _params) do
    render conn, "welcome.html", layout: {SignDict.LayoutView, "empty.html"},
      sign_count: sign_count(), title: gettext("Welcome")
  end

  def about(conn, _params) do
    render conn, "about.html", layout: {SignDict.LayoutView, "app.html"},
      title: gettext("About")
  end

  defp sign_count do
    Repo.aggregate(SignDict.Video, :count, :id)
  end
end
