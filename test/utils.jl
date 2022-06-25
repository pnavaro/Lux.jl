using Lux, ComponentArrays, CUDA, ReverseDiff, Random, Zygote, Test

include("test_utils.jl")

rng = Random.default_rng()
Random.seed!(rng, 0)

@testset "_nfan" begin
    # Fallback
    @test Lux._nfan() == (1, 1)
    # Vector
    @test Lux._nfan(4) == (1, 4)
    # Matrix
    @test Lux._nfan(4, 5) == (5, 4)
    # Tuple
    @test Lux._nfan((4, 5, 6)) == Lux._nfan(4, 5, 6)
    # Convolution
    @test Lux._nfan(4, 5, 6) == 4 .* (5, 6)
end

@testset "replicate" begin
    @test randn(rng, 10, 2) != randn(rng, 10, 2)
    @test randn(Lux.replicate(rng), 10, 2) == randn(Lux.replicate(rng), 10, 2)

    if CUDA.functional()
        curng = CUDA.RNG()
        @test randn(curng, 10, 2) != randn(curng, 10, 2)
        @test randn(Lux.replicate(curng), 10, 2) == randn(Lux.replicate(curng), 10, 2)
    end
end

@testset "istraining" begin
    @test Lux.istraining(Val(true))
    @test !Lux.istraining(Val(false))
    @test !Lux.istraining((training=Val(false),))
    @test Lux.istraining((training=Val(true),))
    @test !Lux.istraining((no_training=1,))
    @test_throws MethodError Lux.istraining((training=true,))
end

@testset "multigate" begin
    x = randn(rng, 10, 1)
    x1, x2 = Lux.multigate(x, Val(2))

    @test x1 == x[1:5, :]
    @test x2 == x[6:10, :]
    @inferred Lux.multigate(x, Val(2))

    run_JET_tests(Lux.multigate, x, Val(2))

    x = randn(rng, 10)
    x1, x2 = Lux.multigate(x, Val(2))

    @test x1 == x[1:5]
    @test x2 == x[6:10]
    @inferred Lux.multigate(x, Val(2))

    run_JET_tests(Lux.multigate, x, Val(2))
end
