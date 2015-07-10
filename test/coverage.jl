if VERSION ≥ v"0.4-dev"
    Pkg.add("Coverage")
    using Coverage
    Codecov.submit(Codecov.process_folder())
end
