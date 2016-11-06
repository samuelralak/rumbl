#############################################
# processes the request info and transfomrs #
# the conn adding :current_user to          #
# conn.assigns                              #
#############################################

defmodule Rumbl.Auth do
  import Plug.Conn

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
    user    = user_id && repo.get(Rumb.User, user_id)
    # assign result in the connection ,
    # this way current_user will always be accessible
    # in all downstream functions including views and controllers
    assign(conn, :current_user, user)
  end
end
