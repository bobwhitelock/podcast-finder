module Main exposing (..)

import Debounce exposing (Debounce)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D
import RemoteData exposing (RemoteData(..), WebData)
import Time exposing (second)


---- MODEL ----


type alias Model =
    { query : String
    , debounce : Debounce String
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
      , debounce = Debounce.init
      , results = NotAsked
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = ChangeQuery String
    | PerformSearch
    | SearchResponse (WebData (List Episode))
    | DebounceMsg Debounce.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeQuery newQuery ->
            let
                ( debounce, cmd ) =
                    Debounce.push debounceConfig newQuery model.debounce
            in
            ( { model
                | query = newQuery
                , debounce = debounce
              }
            , cmd
            )

        PerformSearch ->
            ( { model | results = Loading }
            , performSearch model.query
            )

        SearchResponse response ->
            ( { model | results = response }
            , Cmd.none
            )

        DebounceMsg msg ->
            let
                ( debounce, cmd ) =
                    Debounce.update
                        debounceConfig
                        (Debounce.takeLast performSearch)
                        msg
                        model.debounce
            in
            { model | debounce = debounce } ! [ cmd ]


debounceConfig : Debounce.Config Msg
debounceConfig =
    { strategy = Debounce.later (0.5 * second)
    , transform = DebounceMsg
    }


performSearch : String -> Cmd Msg
performSearch query =
    if String.isEmpty query then
        Cmd.none
    else
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
    div [ class "center mw9 pa4" ]
        [ Html.form
            [ onSubmit PerformSearch
            , class "mw-100 cf pa3"
            ]
            [ input
                [ value model.query
                , placeholder "Search for a person or topic..."
                , onInput ChangeQuery
                , class "w-100 h2 br1"
                ]
                []
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
            viewEpisodes episodes


viewEpisodes : List Episode -> Html Msg
viewEpisodes episodes =
    div [ class "cf pa2" ] (List.map episodeCard episodes)


episodeCard : Episode -> Html Msg
episodeCard episode =
    div [ class "fl w-50 w-25-m w-20-l pa2" ]
        [ a
            [ class "db link dim tc" ]
            [ img
                [ alt (episode.show_title ++ " — " ++ episode.title)
                , class "w-100 db outline black-10"
                , src episode.image_url
                ]
                []
            , dl [ class "mt2 f6 lh-copy" ]
                [ dt [ class "clip" ]
                    [ text "Show Title" ]
                , dd [ class "ml0 black truncate w-100" ]
                    [ text episode.show_title ]
                , dt [ class "clip" ]
                    [ text "Episode Title" ]
                , dd [ class "ml0 gray truncate w-100" ]
                    [ text episode.title ]
                ]
            ]
        ]



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
