# Radarr Movie Sort

This script will automatically sort new downloaded movies based on filter functions selected & their parameters defined in the .env file

## Installation

1. Clone the repo into folder accessible by radarr 
2. Make sure all files have permissions and are executable
3. Add script to Radarr
    1. Settings > Connect > Add Custom Script
    2. Give script title
    3. Only check 'On Import'
    4. Click Save
4. Rename .env.example file to .env
5. Create all the filter folders in filesystem

## Edit .env file

1. `RADARR_DOMAIN` - your radarr domain for api access. 
    * Cloudbox localhost is set by default.
    * **DO NOT** add the trailing slash " / "

2. `RADARR_API_KEY` - your radarr API Key
    * Found in Radarr > Settings > General > API Key

3. `TMDB_API_KEY` - your TMDB API.
    * Used for keyword & genre sorting
    * Sign up here - [TMDB API Documentation](https://developers.themoviedb.org/3/getting-started/introduction)

4. `ROOT_PATH` - root path where your Radarr movies are stored.
    * Radarr > Settings > Media Management > Root Path

5. `EXTRA_PATH` - in case your movies are stored in a seperate folder one level down i.e `/movies/unsorted`
    * Cloudbox default path is prefilled in `ROOT_PATH`

6. `REMOVE_THE_WORDS` - Set to `TRUE` or `FALSE` depending if you want to remove any words from the front of the movie folder
    * Default words are `The` & `A`
    * `WORDS_TO_REMOVE[1]="The"`
    * `WORDS_TO_REMOVE[2]="A"`

7. `SORT_YEARS=TRUE` - set to `TRUE` or `FALSE` depending if you want to sort movies by years.
    * `YEARS_TO_SORT_JSON` - set as an array of JSON
    * `start_year` - start year of sorting range
    * `end_year` - end year of sorting range
    * `folder` - folder to move sorted movies to
    * Default example below: 
        ```
        YEARS_TO_SORT_JSON='[
            {
            "start_year": 2021,
            "end_year": 2021,
            "folder": "latest"
            },
            {
            "start_year": 1900,
            "end_year": "2020",
            "folder": "archive"
            }
        ]'
        ```
8. `FILTER_KEYWORDS=TRUE`- set to `TRUE` or `FALSE` depending if you want to sort movies by TMDB keywords.
    * `FILTER_KEYWORD_JSON` - set as an array of JSON
    * `keyword` - TMDB movie keyword to filter by
    * `folder` - folder to move filtered movies to
    * Default example below: 
        ```
        FILTER_KEYWORD_JSON='[
            {
            "keyword": "stand-up comedy",
            "folder": "standup"
            },
            {
            "keyword": "christmas",
            "folder": "christmas"
            }
        ]'
        ```

9. `FILTER_GENRES=TRUE`- set to `TRUE` or `FALSE` depending if you want to sort movies by TMDB genres.
    * `FILTER_GENRE_JSON` - set as an array of JSON
    * `genre` - TMDB movie genre to filter by
    * `folder` - folder to move filtered movies to
    * List of genres available from [TMDB Genre List](https://developers.themoviedb.org/3/genres/get-movie-list) - * you require a TMDB API Key
    * Default example below: 
        ```
        FILTER_GENRE_JSON='[
            {
            "genre": "Family",
            "folder": "kids"
            },
            {
            "genre": "Animation",
            "folder": "kids"
            },
            {
            "genre": "Documentary",
            "folder": "documentary"
            }
        ]'
        ```
10. Running Order
    * Change the number in the square brackets for each function for the order you would like to filter your movies in. Number 1 will be run first.
    * As soon as a positive match in a sorting/filtering function is found, the script will edit & move the movie then exits:
        * e.g - if you are sorting movied by kids genre and year and would like a 2020 kids movie to be in the latest folder then you should have higher priority for `sort_years` before `filter_genres` & `filter_keywords`.
    * The run order is overridden by whether you have enabled that filter or not:
        * e.g if you have `filter_genres` in order 1 but have disabled it by selecting `FILTER_GENRES=FALSE` then `filter_genres` will not run
    * `remove_words` **MUST** be run in position 1 if you wish to use it.
    * Default example below:
        ```
        RUN_ORDER[1]=remove_words
        RUN_ORDER[2]=filter_genres
        RUN_ORDER[3]=filter_keywords
        RUN_ORDER[4]=sort_years
        ```