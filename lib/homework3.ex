defmodule Homework3 do
  use Supervisor

  def start() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Supervisor.init(
      [
        {Morning, []}
      ],
      strategy: :one_for_one
    )
  end
end

defmodule Morning do
  use Supervisor

  def start_link(how) do
    Supervisor.start_link(__MODULE__, how, name: __MODULE__)
  end

  def init(how) do
    IO.inspect(how, label: "Woke up")
    mode = get_mode(how)

    processes = [
      {Hygiene, mode},
      {Breakfast, mode},
      {Clothing, []}
    ]

    Supervisor.init(processes,
      strategy: :one_for_one
    )
  end

  defp get_mode(:early), do: :slow
  defp get_mode(:late), do: :fast
  defp get_mode(_), do: :normal
end

defmodule Hygiene do
  @default_counter 50
  @duration 6000
  @fee 5
  use Task

  defmodule Exception do
    defexception message: "Imaginary parent: Not so fast, my child, #{@fee} more swipes."
  end

  def start_link(:slow) do
    Task.start_link(fn -> brush_teeth(60) end)
  end

  def start_link(:fast) do
    Task.start_link(fn -> brush_teeth(40) end)
  end

  def start_link(_) do
    Task.start_link(fn -> brush_teeth(@default_counter) end)
  end

  defp clean_a_teeth() do
    swipe_time = 50 + :rand.uniform(101 - 50)
    Process.sleep(swipe_time)
    swipe_time
  end

  def brush_teeth(swipe_counter, total_time \\ 0)

  def brush_teeth(swipe_counter, total_time) when swipe_counter > 0 do
    IO.puts("Me: I swiped the brush so many times, and #{swipe_counter} times to go!")
    brush_teeth(swipe_counter - 1, total_time + clean_a_teeth())
  end

  def brush_teeth(swipe_counter, total_time) when swipe_counter === 0 do
    swipe_time = 50 + :rand.uniform(101 - 50)
    Process.sleep(swipe_time)
    IO.puts("Me: Now my teeth are clean.")

    try do
      validate(total_time, swipe_counter)
    rescue
      Hygiene.Exception -> bargain(total_time)
      _ -> IO.puts("Me: Whoopsy!")
    end
  end

  defp validate(total_time, swipe_counter)
       when total_time < @duration and swipe_counter == 0 do
    IO.puts("Imaginary parent: Wow, that was way too fast")
    raise Hygiene.Exception
  end

  defp validate(_total_time, _swipe_counter), do: :ok

  defp bargain(total_time) when total_time > @duration - 1000 do
    IO.puts("Me: I'll catch up in the evening")
    Breakfast.stop_boiling()
  end

  defp bargain(total_time) do
    IO.puts("Me: Alright, fine!")
    brush_teeth(@fee, total_time)
  end
end

defmodule Breakfast do
  use Task

  def start_link(:slow) do
    Task.start_link(fn -> make_coffee(300) end)
  end

  def start_link(:fast) do
    Task.start_link(fn -> make_coffee(60) end)
  end

  def start_link(_) do
    Task.start_link(fn -> make_coffee(180) end)
  end

  def make_coffee(counter, stopped \\ false)

  def make_coffee(counter, false) when counter > 0 do
    IO.puts("The coffee will be ready in #{counter} seconds")

    receive do
      :done ->
        make_coffee(0, true)
    after
      1000 -> make_coffee(counter - 10)
    end
  end

  def make_coffee(0, false) do
    raise "Coffee has run away, so no coffee today!"
  end

  def make_coffee(_, true) do
    IO.puts("Coffee is ready!")
  end

  def stop_boiling() do
    IO.puts(
      "Trying to stop the coffee-making process... but the self() is pointing to another PID."
    )

    send(self(), :done)
  end
end

defmodule Clothing do
  use Task

  def start_link(mode) do
    Task.start_link(fn -> find_clothes() end)
  end

  def find_clothes() do
    case receive_sign_from_the_universe() do
      true ->
        raise "Me: I've got nothing to wear!"

      _ ->
        IO.puts("Me: I've got nothing to wear, except for my favourite jeans!")
    end
  end

  defp receive_sign_from_the_universe do
    :rand.uniform(50) > 25
  end
end

Homework3.start()
