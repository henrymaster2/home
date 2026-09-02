defmodule HomeWeb.ProfileLive do
  use HomeWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
  ~H"""
  <main class="min-h-screen w-full flex items-center justify-center bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 px-5">

    <div class="w-full max-w-md">

      <!-- Logo / Brand -->
      <div class="mb-10 text-center">
        <div class="mx-auto mb-5 flex h-20 w-20 items-center justify-center rounded-3xl bg-gradient-to-br from-blue-500 to-indigo-600 shadow-xl shadow-blue-500/20">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-10 w-10 text-white"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M3 10.5 12 3l9 7.5V21a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1v-10.5Z" />
          </svg>
        </div>

        <h1 class="text-3xl font-bold tracking-tight text-white">
          Welcome to Home
        </h1>

        <p class="mt-3 text-sm leading-6 text-slate-400">
          Sign in to save properties, manage your listings and access your account.
        </p>
      </div>

      <!-- Sign In Card -->
      <div class="rounded-3xl border border-white/10 bg-white/[0.04] p-6 shadow-2xl backdrop-blur-xl">

        <!-- Google -->
        <button
          type="button"
          class="flex w-full items-center justify-center gap-3 rounded-2xl border border-white/10 bg-white px-5 py-4 text-sm font-semibold text-slate-900 transition duration-200 hover:scale-[1.02] hover:bg-slate-100 active:scale-[0.98]"
        >
          <svg class="h-5 w-5" viewBox="0 0 24 24">
            <path
              fill="#4285F4"
              d="M21.35 12.27c0-.79-.07-1.55-.2-2.27H12v4.3h5.23a4.47 4.47 0 0 1-1.94 2.93v2.78h3.14c1.84-1.69 2.92-4.18 2.92-7.01Z"
            />
            <path
              fill="#34A853"
              d="M12 21.75c2.62 0 4.82-.87 6.43-2.36l-3.14-2.78c-.87.58-1.99.92-3.29.92-2.53 0-4.67-1.71-5.44-4.01H3.32v2.87A9.72 9.72 0 0 0 12 21.75Z"
            />
            <path
              fill="#FBBC05"
              d="M6.56 13.52A5.84 5.84 0 0 1 6.26 12c0-.53.1-1.03.3-1.52V7.61H3.32A9.75 9.75 0 0 0 2.25 12c0 1.57.38 3.06 1.07 4.39l3.24-2.87Z"
            />
            <path
              fill="#EA4335"
              d="M12 6.47c1.43 0 2.71.49 3.72 1.45l2.79-2.79C16.81 3.54 14.61 2.25 12 2.25a9.72 9.72 0 0 0-8.68 5.36l3.24 2.87c.77-2.3 2.91-4.01 5.44-4.01Z"
            />
          </svg>

          Continue with Google
        </button>

        <!-- Apple -->
        <button
          type="button"
          class="mt-4 flex w-full items-center justify-center gap-3 rounded-2xl bg-white py-4 text-sm font-semibold text-slate-950 transition duration-200 hover:scale-[1.02] hover:bg-slate-200 active:scale-[0.98]"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5"
            viewBox="0 0 24 24"
            fill="currentColor"
          >
            <path d="M16.67 12.27c0-2.15 1.76-3.19 1.84-3.24a3.96 3.96 0 0 0-3.11-1.68c-1.31-.14-2.58.79-3.25.79-.68 0-1.7-.77-2.81-.75a4.13 4.13 0 0 0-3.47 2.12c-1.5 2.6-.38 6.42 1.06 8.53.72 1.03 1.55 2.18 2.64 2.14 1.06-.04 1.46-.68 2.74-.68 1.27 0 1.63.68 2.75.65 1.15-.02 1.87-1.03 2.56-2.07.83-1.18 1.16-2.34 1.18-2.4-.03-.01-2.13-.81-2.13-3.41Z" />
            <path d="M14.54 6.06c.58-.73.98-1.72.87-2.73-.84.04-1.89.58-2.49 1.29-.54.64-1.02 1.67-.89 2.63.95.07 1.92-.48 2.51-1.19Z" />
          </svg>

          Continue with Apple
        </button>

        <!-- Divider -->
        <div class="my-7 flex items-center gap-4">
          <div class="h-px flex-1 bg-white/10"></div>
          <span class="text-xs text-slate-500">OR</span>
          <div class="h-px flex-1 bg-white/10"></div>
        </div>

        <!-- Guest -->
        <button
          type="button"
          class="w-full rounded-2xl border border-white/10 bg-white/5 py-4 text-sm font-medium text-slate-300 transition hover:bg-white/10 hover:text-white"
        >
          Continue as guest
        </button>

      </div>

      <p class="mt-7 text-center text-xs leading-5 text-slate-500">
        By continuing, you agree to our
        <span class="text-slate-300">Terms of Service</span>
        and
        <span class="text-slate-300">Privacy Policy</span>.
      </p>

    </div>
  </main>
  """
end
end
