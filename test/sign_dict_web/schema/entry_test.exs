defmodule SignDict.Schema.EntryTest do
  use SignDict.ConnCase, async: true
  import SignDict.Factory
  alias SignDict.Test.Helpers.Absinthe, as: AbsintheHelper

  describe "Get all entries" do
    test "Paginates entries", %{conn: conn} do
      insert(:entry_with_current_video, text: "Coconuts")
      insert(:entry_with_current_video, text: "Bananas")
      entry_3 = insert(:entry_with_current_video, text: "Blueberries")
      entry_4 = insert(:entry, text: "Grapes")

      query = """
        {
          index(perPage: 2, page: 2){
          current_video{
            copyright
            license
            originalHref
            videoUrl
            thumbnailUrl
              user{
                name
              }
            }
            description
            id
            language{
              iso6393
              longName
              shortName
            }
            text
            type
            url
            videos{
              copyright
              license
              originalHref
              videoUrl
              thumbnailUrl
              user{
                name
              }
            }
          }
        }
      """

      response =
        conn
        |> post(api_path(), AbsintheHelper.query_skeleton(query, "entry"))
        |> json_response(200)

      assert(
        %{
          "data" => %{
            "index" => [
              %{
                "language" => entry_3.language |> expected_language(),
                "videos" => entry_3.videos |> Enum.map(fn v -> expected_entry_video(v) end),
                "current_video" => entry_3.current_video |> expected_entry_video(),
                "text" => "#{entry_3.text}",
                "description" => "#{entry_3.description}",
                "type" => "#{entry_3.type}",
                "url" => "https://localhost/entry/#{entry_3.id}",
                "id" => entry_3.id
              },
              %{
                "language" => entry_4.language |> expected_language(),
                "videos" => [],
                "current_video" => nil,
                "text" => "#{entry_4.text}",
                "description" => "#{entry_4.description}",
                "type" => "#{entry_4.type}",
                "url" => "https://localhost/entry/#{entry_4.id}",
                "id" => entry_4.id
              }
            ]
          }
        } == response
      )
    end
  end

  describe "Get entry by ID" do
    test "Successfully returns entry", %{conn: conn} do
      entry = insert(:entry_with_current_video)

      query = """
      {
        entry(id: #{entry.id}) {
          id
          text
          description
          type
          url
          videos{
            copyright
            license
            originalHref
            videoUrl
            thumbnailUrl
            user{
              name
            }
          }
          current_video{
            copyright
            license
            originalHref
            videoUrl
            thumbnailUrl
            user{
              name
            }
          }
          language{
            iso6393
            longName
            shortName
          }
        }
      }
      """

      response =
        conn
        |> post(api_path(), AbsintheHelper.query_skeleton(query, "entry"))
        |> json_response(200)

      assert(
        %{
          "data" => %{
            "entry" => %{
              "language" => entry.language |> expected_language(),
              "videos" => entry.videos |> Enum.map(fn v -> expected_entry_video(v) end),
              "current_video" => entry.current_video |> expected_entry_video(),
              "text" => "#{entry.text}",
              "description" => "#{entry.description}",
              "type" => "#{entry.type}",
              "url" => "https://localhost/entry/#{entry.id}",
              "id" => entry.id
            }
          }
        } == response
      )
    end

    test "Returns message if entry not found", %{conn: conn} do
      query = """
      {
        entry(id: 10000000) {
          text
        }
      }
      """

      response =
        conn
        |> post(api_path(), AbsintheHelper.query_skeleton(query, "entry"))
        |> json_response(200)

      assert(
        %{
          "data" => %{"entry" => nil},
          "errors" => [
            %{
              "message" => "Not found",
              "path" => ["entry"]
            }
          ]
        } = response
      )
    end
  end

  describe "Search entry by word" do
    test "Successfully returns entry", %{conn: conn} do
      entry_1 = insert(:entry_with_current_video, text: "Zug")
      insert(:entry_with_current_video, text: "Eisenbahn")

      query = """
      {
        search(word: "Zug") {
          id
          text
          description
          type
          url
          videos{
            copyright
            license
            originalHref
            videoUrl
            thumbnailUrl
            user{
              name
            }
          }
          current_video{
            copyright
            license
            originalHref
            videoUrl
            thumbnailUrl
            user{
              name
            }
          }
          language{
            iso6393
            longName
            shortName
          }
        }
      }
      """

      response =
        conn
        |> post(api_path(), AbsintheHelper.query_skeleton(query, "search"))
        |> json_response(200)

      assert(
        %{
          "data" => %{
            "search" => [
              %{
                "language" => expected_language(entry_1.language),
                "videos" => entry_1.videos |> Enum.map(fn v -> expected_entry_video(v) end),
                "current_video" => entry_1.current_video |> expected_entry_video(),
                "text" => "#{entry_1.text}",
                "description" => "#{entry_1.description}",
                "type" => "#{entry_1.type}",
                "id" => entry_1.id,
                "url" => "https://localhost/entry/#{entry_1.id}"
              }
            ]
          }
        } == response
      )
    end

    test "returns all entries for letter 'Z'", %{conn: conn} do
      insert(:entry_with_current_video, text: "Zug")
      insert(:entry_with_current_video, text: "Zahnpasta")
      insert(:entry_with_current_video, text: "Zirkel")
      insert(:entry_with_current_video, text: "Elefant")

      query = """
      {
        search(letter: "Z") {
          text
        }
      }
      """

      response =
        conn
        |> post(api_path(), AbsintheHelper.query_skeleton(query, "search"))
        |> json_response(200)

      assert(
        %{
          "data" => %{
            "search" => [
              %{"text" => "Zahnpasta"},
              %{"text" => "Zirkel"},
              %{"text" => "Zug"}
            ]
          }
        } == response
      )
    end

    test "returns all entries matching search text", %{conn: conn} do
      insert(:entry_with_current_video, text: "Familie")
      insert(:entry_with_current_video, text: "Familienfest")

      query = """
      {
        search(word: "Familie") {
          text
        }
      }
      """

      response =
        conn
        |> post(api_path(), AbsintheHelper.query_skeleton(query, "search"))
        |> json_response(200)

      assert(
        ["Familie", "Familienfest"] ==
          response["data"]["search"]
          |> Enum.map(&Map.get(&1, "text"))
          |> Enum.sort()
      )
    end
  end

  defp expected_entry_video(video) do
    %{
      "copyright" => "#{video.copyright}",
      "license" => "#{video.license}",
      "originalHref" => "#{video.original_href}",
      "thumbnailUrl" => "#{video.thumbnail_url}",
      "videoUrl" => "#{video.video_url}",
      "user" => %{
        "name" => "#{video.user.name}"
      }
    }
  end

  defp expected_language(language) do
    %{
      "iso6393" => "#{language.iso6393}",
      "longName" => "#{language.long_name}",
      "shortName" => "#{language.short_name}"
    }
  end

  defp api_path do
    "/graphql-api/graphql"
  end
end
