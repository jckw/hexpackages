defmodule ElixirPackages.PackageGrids do
  @moduledoc """
  The PackageGrids context.
  """

  import Ecto.Query, warn: false
  alias ElixirPackages.Repo
  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias ElixirPackages.PackageGrids.{Grid, Package, PackageInGrid, SyncPackageData}

  @pagination [page_size: 15]
  @pagination_distance 5

  @doc """
  Paginate the list of grids using filtrex
  filters.

  ## Examples

      iex> list_grids(%{})
      %{grids: [%Grid{}], ...}
  """
  @spec paginate_grids(map) :: {:ok, map} | {:error, any}
  def paginate_grids(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <- Filtrex.parse_params(filter_config(:grids), params["grid"] || %{}),
         %Scrivener.Page{} = page <- do_paginate_grids(filter, params) do
      {:ok,
       %{
         grids: page.entries,
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_entries: page.total_entries,
         distance: @pagination_distance,
         sort_field: sort_field,
         sort_direction: sort_direction
       }}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp do_paginate_grids(filter, params) do
    Grid
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  @doc """
  Returns the list of grids.

  ## Examples

      iex> list_grids()
      [%Grid{}, ...]

  """
  def list_grids do
    Repo.all(Grid)
  end

  @doc """
  Returns the list of grids in alphabetical order.

  ## Examples

      iex> list_grids_alphabetically()
      [%Grid{}, ...]

  """
  def list_grids_alphabetically do
    Grid
    |> order_by(asc: :name)
    |> Repo.all()
  end

  @doc """
  Gets a single grid.

  Raises `Ecto.NoResultsError` if the Grid does not exist.

  ## Examples

      iex> get_grid!(123)
      %Grid{}

      iex> get_grid!(456)
      ** (Ecto.NoResultsError)

  """
  def get_grid!(id), do: Repo.get!(Grid, id)

  def get_grid_by_slug!(slug), do: Repo.get_by!(Grid, slug: slug)

  @doc """
  Creates a grid.

  ## Examples

      iex> create_grid(%{field: value})
      {:ok, %Grid{}}

      iex> create_grid(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_grid(attrs \\ %{}) do
    %Grid{}
    |> Grid.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a grid.

  ## Examples

      iex> update_grid(grid, %{field: new_value})
      {:ok, %Grid{}}

      iex> update_grid(grid, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_grid(%Grid{} = grid, attrs) do
    grid
    |> Grid.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Grid.

  ## Examples

      iex> delete_grid(grid)
      {:ok, %Grid{}}

      iex> delete_grid(grid)
      {:error, %Ecto.Changeset{}}

  """
  def delete_grid(%Grid{} = grid) do
    Repo.delete(grid)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking grid changes.

  ## Examples

      iex> change_grid(grid)
      %Ecto.Changeset{source: %Grid{}}

  """
  def change_grid(%Grid{} = grid, attrs \\ %{}) do
    Grid.changeset(grid, attrs)
  end

  defp filter_config(:grids) do
    defconfig do
      text(:name)
      text(:description)
    end
  end

  defp filter_config(:packages) do
    defconfig do
      text(:name)
    end
  end

  @doc """
  Paginate the list of packages using filtrex
  filters.

  ## Examples

      iex> list_packages(%{})
      %{packages: [%Package{}], ...}
  """
  @spec paginate_packages(map) :: {:ok, map} | {:error, any}
  def paginate_packages(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <-
           Filtrex.parse_params(filter_config(:packages), params["package"] || %{}),
         %Scrivener.Page{} = page <- do_paginate_packages(filter, params) do
      {:ok,
       %{
         packages: page.entries,
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_entries: page.total_entries,
         distance: @pagination_distance,
         sort_field: sort_field,
         sort_direction: sort_direction
       }}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp do_paginate_packages(filter, params) do
    Package
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  @doc """
  Returns the list of packages.

  ## Examples

      iex> list_packages()
      [%Package{}, ...]

  """
  def list_packages do
    Repo.all(Package)
  end

  @doc """
  Gets a single package.

  Raises `Ecto.NoResultsError` if the Package does not exist.

  ## Examples

      iex> get_package!(123)
      %Package{}

      iex> get_package!(456)
      ** (Ecto.NoResultsError)

  """
  def get_package!(id), do: Repo.get!(Package, id)

  @doc """
  Creates a package.

  ## Examples

      iex> create_package(%{field: value})
      {:ok, %Package{}}

      iex> create_package(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_package(attrs \\ %{}) do
    %Package{}
    |> Package.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, package} ->
        Task.start(fn -> SyncPackageData.sync_package_data(package) end)
        {:ok, package}

      x ->
        x
    end
  end

  @doc """
  Updates a package.

  ## Examples

      iex> update_package(package, %{field: new_value})
      {:ok, %Package{}}

      iex> update_package(package, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_package(%Package{} = package, attrs) do
    package
    |> Package.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Package.

  ## Examples

      iex> delete_package(package)
      {:ok, %Package{}}

      iex> delete_package(package)
      {:error, %Ecto.Changeset{}}

  """
  def delete_package(%Package{} = package) do
    Repo.delete(package)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking package changes.

  ## Examples

      iex> change_package(package)
      %Ecto.Changeset{source: %Package{}}

  """
  def change_package(%Package{} = package, attrs \\ %{}) do
    Package.changeset(package, attrs)
  end

  @doc """
  Creates a package_in_grid.

  ## Examples

      iex> create_package_in_grid(%{field: value})
      {:ok, %PackageInGrid{}}

      iex> create_package_in_grid(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_package_in_grid(attrs \\ %{}) do
    %PackageInGrid{}
    |> PackageInGrid.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a PackageInGrid.

  ## Examples

      iex> delete_package_in_grid(package_in_grid)
      {:ok, %PackageInGrid{}}

      iex> delete_package_in_grid(package_in_grid)
      {:error, %Ecto.Changeset{}}

  """
  def delete_package_in_grid(%PackageInGrid{} = package_in_grid) do
    Repo.delete_all(
      from pg in "package_in_grid",
        where:
          pg.package_id == ^package_in_grid.package_id and pg.grid_id == ^package_in_grid.grid_id
    )
    |> case do
      {1, nil} -> {:ok, package_in_grid}
      _ -> {:error, change_package_in_grid(package_in_grid)}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking packge-in-grid changes.

  ## Examples

      iex> change_package_in_grid(package_in_grid)
      %Ecto.Changeset{source: %PackageInGrid{}}

  """
  def change_package_in_grid(%PackageInGrid{} = package_in_grid, attrs \\ %{}) do
    PackageInGrid.changeset(package_in_grid, attrs)
  end
end
