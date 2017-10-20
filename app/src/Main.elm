module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D
import RemoteData exposing (RemoteData(..), WebData)


---- MODEL ----


type alias Model =
    { query : String
    , -- XXX Switch to dict?
      results : WebData (List Episode)
    }


type alias Episode =
    { title : String
    , show_title : String
    , date : String
    , player_url : String
    , image_url : String
    }


init : ( Model, Cmd Msg )
init =
    ( { query = ""
      , results = NotAsked
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = ChangeQuery String
    | PerformSearch
    | SearchResponse (WebData (List Episode))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeQuery newQuery ->
            ( { model | query = newQuery }
            , Cmd.none
            )

        PerformSearch ->
            ( { model | results = Loading }
            , performSearch model.query
            )

        SearchResponse response ->
            ( { model | results = response }
            , Cmd.none
            )


performSearch : String -> Cmd Msg
performSearch query =
    Http.get (searchUrl query) decodeSearchResults
        |> RemoteData.sendRequest
        |> Cmd.map SearchResponse


searchUrl : String -> String
searchUrl query =
    searchEndpoint ++ "?query=" ++ Http.encodeUri query


searchEndpoint : String
searchEndpoint =
    "/dev/search"


decodeSearchResults : D.Decoder (List Episode)
decodeSearchResults =
    D.field "results" (D.list decodeEpisode)


decodeEpisode : D.Decoder Episode
decodeEpisode =
    D.map5 Episode
        (D.field "title" D.string)
        (D.field "show_title" D.string)
        (D.field "date_created" D.string)
        (D.at [ "urls", "ui" ] D.string)
        (D.at [ "image_urls", "full" ] D.string)



---- VIEW ----


view : Model -> Html Msg
view model =
    let
        disableSubmit =
            String.isEmpty model.query
                || RemoteData.isLoading model.results
    in
    div []
        [ Html.form [ onSubmit PerformSearch ]
            [ input
                [ value model.query, onInput ChangeQuery ]
                []
            , button [ disabled disableSubmit ] [ text "Go!" ]
            ]
        , viewResults model.results
        ]


viewResults : WebData (List Episode) -> Html Msg
viewResults results =
    case results of
        NotAsked ->
            div [] []

        Loading ->
            div [] [ text "Loading..." ]

        Failure error ->
            div [] [ toString error |> text ]

        Success episodes ->
            div [] [ toString episodes |> text ]



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
