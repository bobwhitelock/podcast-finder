module Main exposing (..)

import Debounce exposing (Debounce)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D
import RemoteData exposing (RemoteData(..), WebData)
import Tachyons exposing (..)
import Tachyons.Classes as T exposing (..)
import Time exposing (second)


---- MODEL ----


type alias Model =
    { query : String
    , debounce : Debounce String
    , results : Dict String (WebData (List Episode))
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
      , results = Dict.empty
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = ChangeQuery String
    | PerformSearch
    | SearchResponse String (WebData (List Episode))
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
            let
                ( shouldSearch, newModel ) =
                    shouldSearchWithNewModel model model.query

                cmd =
                    if shouldSearch then
                        performSearch model.query
                    else
                        Cmd.none
            in
            ( newModel, cmd )

        SearchResponse query response ->
            ( { model
                | results = Dict.insert query response model.results
              }
            , Cmd.none
            )

        DebounceMsg msg ->
            let
                ( shouldSearch, newModel ) =
                    shouldSearchWithNewModel model model.query

                cmd =
                    if shouldSearch then
                        performSearch
                    else
                        \_ -> Cmd.none

                ( debounce, debounceCmd ) =
                    Debounce.update
                        debounceConfig
                        (Debounce.takeLast cmd)
                        msg
                        model.debounce
            in
            { newModel | debounce = debounce } ! [ debounceCmd ]


debounceConfig : Debounce.Config Msg
debounceConfig =
    { strategy = Debounce.later (0.5 * second)
    , transform = DebounceMsg
    }


shouldSearchWithNewModel : Model -> String -> ( Bool, Model )
shouldSearchWithNewModel model query =
    if String.isEmpty query then
        ( False, model )
    else
        let
            existingResults =
                Dict.get query model.results
                    |> Maybe.withDefault NotAsked

            ( shouldSearch_, newResultsState ) =
                if RemoteData.isSuccess existingResults then
                    ( False, existingResults )
                else
                    -- XXX This will cause things to be saved in Dict as
                    -- Loading even if the request won't be sent due to
                    -- debouncing - should only set as Loading when sending a
                    -- request (in debounce case this function is more like
                    -- `canSearch`).
                    ( True, Loading )
        in
        ( shouldSearch_
        , { model
            | results = Dict.insert query newResultsState model.results
          }
        )


performSearch : String -> Cmd Msg
performSearch query =
    Http.get (searchUrl query) decodeSearchResults
        |> RemoteData.sendRequest
        |> Cmd.map (SearchResponse query)


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
        currentResults =
            Dict.get model.query model.results
                |> Maybe.withDefault NotAsked
    in
    div [ classes [ center, mw9, pa4 ] ]
        [ Html.form
            [ onSubmit PerformSearch
            , classes [ mw_100, cf, pa3 ]
            ]
            [ input
                [ value model.query
                , placeholder "Search for a person or topic..."
                , onInput ChangeQuery
                , classes [ w_100, T.h2, br1 ]
                ]
                []
            ]
        , viewResults currentResults
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
    div
        [ classes [ cf, pa2 ] ]
        (List.map episodeCard episodes)


episodeCard : Episode -> Html Msg
episodeCard episode =
    div [ classes [ fl, w_50, w_25_m, w_20_l, pa2 ] ]
        [ a
            [ classes [ db, link, dim, tc ] ]
            [ img
                [ alt (episode.show_title ++ " — " ++ episode.title)
                , classes [ w_100, db, outline, black_10 ]
                , src episode.image_url
                ]
                []
            , dl [ classes [ mt2, f6, lh_copy ] ]
                [ Html.dt [ classes [ clip ] ]
                    [ text "Show Title" ]
                , dd [ classes [ ml0, black, w_100 ] ]
                    [ text episode.show_title ]
                , Html.dt [ classes [ clip ] ]
                    [ text "Episode Title" ]
                , dd [ classes [ ml0, gray, w_100 ] ]
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
