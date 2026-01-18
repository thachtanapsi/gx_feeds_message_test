defmodule GxFeedsMessageTest.FullDayMessageWorker.Worker do
  use GenServer

  @batch_size 2000

  @doc """
  Chạy việc gửi message từ file log vào UDP server.

  ## Parameters

  - `path_dir`: Đường dẫn đến thư mục chứa file log.

  ## Examples

  iex> GxFeedsMessageTest.FullDayMessageWorker.Worker.run_send_message("message_data/20260116")
  """

  def run_send_message(path_dir) do
    GenServer.cast(__MODULE__, {:send_message, path_dir})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    {:ok, opts}
  end

  def handle_cast({:send_message, path_dir}, state) do
    list_files = File.ls!(path_dir) |> Enum.sort()
    Enum.each(list_files, fn file ->
      file_path = Path.join(path_dir, file)
      send_message(file_path)
    end)
    {:noreply, state}
  end

  defp send_message(file_path) do
    try do
      File.read!(file_path)
      |> String.split("\n")
      |> Enum.filter(fn line -> String.trim(line) != "" end)
      |> Enum.chunk_every(@batch_size)
      |> Enum.each(fn batch ->
        # Xử lý batch @batch_size dòng
        Enum.each(batch, fn line ->
          case UdpSender.parse_log_line(line) do
            {:ok, port, message} ->
              IO.inspect(message)
              IO.inspect(port)
              UdpSender.send_udp(message, {127, 0, 0, 1}, port)
            {:error, _} ->
              :ok
          end
        end)

        # Sleep 1 giây sau mỗi batch để đảm bảo tốc độ @batch_size dòng/giây
        Process.sleep(1000)
      end)
    rescue
      error ->
        :ok
    end
  end
end
