defmodule HomeWeb.UserLive.Registration do
  use HomeWeb, :live_view
  alias Home.Accounts
  alias Home.Accounts.User
  @impl true
  def mount(_params, _session, socket) do
    # We will initialize @form here in the next step
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(:show_password, false)
      |> assign_form(changeset)

    {:ok, socket}
  end

  def handle_event("toggle_password", _params, socket) do
    {:noreply, assign(socket, show_password: !socket.assigns.show_password)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    # Safely extract user params whether nested or top-level
    user_params = Map.get(params, "user", params)

    changeset =
      %Home.Accounts.User{}
      |> Home.Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    result = Accounts.register_user(user_params)
    IO.inspect(result, label: "REGISTRATION RESULT")

    case result do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User created successfully!")
         |> redirect(to: ~p"/users/log-in")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-900 flex items-center justify-center p-4">
      <div class="w-full max-w-md bg-slate-800 p-8 flex flex-col gap-4 rounded-2xl shadow-2xl">
        <p class="font-semibold font-sans text-cyan-50 text-xl text-center">
          Welcome, create new account
        </p>

        <.form
          for={@form}
          id="registration_form"
          phx-change="validate"
          phx-submit="save"
          class="font-sans text-slate-100 placeholder-slate-500 rounded-xl space-y-4"
        >
          <.input
            field={@form[:names]}
            type="text"
            label="Names"
            placeholder="henry masita"
            required
            class="mt-1 block w-full rounded-xl border border-slate-700 bg-slate-900 text-slate-100 placeholder-slate-500 px-3 py-2 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/40"
          />

          <.input
            field={@form[:email]}
            type="email"
            label="Email address"
            placeholder="you@gmail.com"
            required
            class="mt-1 block w-full rounded-xl border border-slate-700 bg-slate-900 text-slate-100 placeholder-slate-500 px-3 py-2 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/40"
          />

          <.input
            field={@form[:phone]}
            type="tel"
            label="Phone number"
            placeholder="0759027692"
            required
            class="mt-1 block w-full rounded-xl border border-slate-700 bg-slate-900 text-slate-100 placeholder-slate-500 px-3 py-2 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/40"
          />
          
    <!-- Custom Password Field with Centered Toggle Button -->
          <div class="flex flex-col gap-1">
            <label class="text-sm font-semibold text-slate-200">Password</label>
            <div class="relative w-full">
              <input
                id={@form[:password].id}
                name={@form[:password].name}
                value={@form[:password].value}
                required
                type={if @show_password, do: "text", else: "password"}
                placeholder="enter pass"
                class="block w-full rounded-xl border border-slate-700 bg-slate-900 text-slate-100 placeholder-slate-500 px-3 py-2 pr-10 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/40"
              />
              <button
                type="button"
                phx-click="toggle_password"
                class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-100 transition-colors duration-150 focus:outline-none"
              >
                <%= if @show_password do %>
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-5 h-5 text-slate-300"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.537-3.007-9.963-7.178Z"
                    />
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"
                    />
                  </svg>
                <% else %>
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-5 h-5 text-slate-300"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M3.98 8.223A10.477 10.477 0 0 0 1.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0 1 12 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 0 1-4.293 5.774M6.228 6.228 3 3m3.228 3.228 3.65 3.65m7.894 7.894L21 21m-3.228-3.65-3.65-3.65m0 0a3 3 0 1 0-4.243-4.243m4.242 4.242L9.88 9.88"
                    />
                  </svg>
                <% end %>
              </button>
            </div>
          </div>
          
    <!-- Custom Confirm Password Field -->
          <div class="flex flex-col gap-1">
            <label class="text-sm font-semibold text-slate-200">Confirm pass</label>
            <input
              id={@form[:confirm_password].id}
              name={@form[:confirm_password].name}
              value={@form[:confirm_password].value}
              required
              type={if @show_password, do: "text", else: "password"}
              placeholder="confirm pass"
              class="block w-full rounded-xl border border-slate-700 bg-slate-900 text-slate-100 placeholder-slate-500 px-3 py-2 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/40"
            />
          </div>

          <.button
            type="submit"
            class="btn btn-primary w-full text-xl pb-3 rounded-2xl px-3 py-2 bg-blue-500 hover:bg-blue-600 text-white mt-2"
          >
            create account
          </.button>
        </.form>

        <p class="text-center text-slate-400">
          already a user? <.link
            navigate={~p"/users/log-in"}
            phx-no-format
            class="text-cyan-400 font-semibold hover:underline"
          >
            Login
          </.link>
        </p>
      </div>
    </div>
    """
  end
end
