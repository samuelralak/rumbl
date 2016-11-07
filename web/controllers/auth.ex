#############################################
# processes the request info and transfomrs #
# the conn adding :current_user to          #
# conn.assigns                              #
#############################################

defmodule Rumbl.Auth do
  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Phoenix.Controller

  alias Rumbl.Router.Helpers

  def init(opts) do
    # extract repository from options
    # fetch function with a bang(!) raises an excepton if
    # key doesnt exist.
    # current module will always require the repo option
    Keyword.fetch!(opts, :repo)
  end

  # function receives the repo from 'init'
  def call(conn, repo) do
    # check if a user is stored in the session
    user_id = get_session(conn, :user_id)
    # look up the user it it exists in the session
    user    = user_id && repo.get(Rumbl.User, user_id)
    # assign result in the connection ,
    # this way current_user will always be accessible
    # in all downstream functions including views and controllers
    assign(conn, :current_user, user)
  end

  # receive the connection and the user
  # and store the user_id in the session
  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end

  def login_by_username_and_pass(conn, username, given_pass, opts) do
    # fetch the repository from the given opts
    repo = Keyword.fetch!(opts, :repo)
    # look up the user with the specified username
    user = repo.get_by(Rumbl.User, username: username)

    cond do
      # if a matching user is found, log in and set the proper
      # assigns and update the session as well
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, login(conn, user)}
      # if user is found but password doesnt match,
      # return unauthorized
      user ->
        {:error, :unauthorized, conn}
      # otherwise return not_found
      true ->
        # simulate password check with variable timing, This hardens our authentication
        # layer against timing attacks,2 which is crucial to keeping our application secure.
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end

  def logout(conn) do
    # drop the whole session at the edn of the request
    # if you only wish to delete the user_id do:
    # Example:
    #     delete_session(conn, :user_id)
    configure_session(conn, drop: true)
  end

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      # if current_user exists
      # retunr the conn unchanged
      conn
    else
      # store a flash message and
      # redirect back to our app root
      conn
      |> put_flash(:error, "You must be logged in to access that page.")
      |> redirect(to: Helpers.page_path(conn, :index))
      |> halt() # stop any downstream transformations
    end
  end
end
