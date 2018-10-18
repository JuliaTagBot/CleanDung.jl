module CleanDung

using DelimitedFiles

export getdata

absfolders(dir) = filter(isdir, [joinpath(abspath(dir), d) for d in readdir(dir) if d[1] ≠ '.'])

# absreaddir(dir) = joinpath.(abspath(dir), readdir(dir))
# nohiddens(path) = all(d[1] ≠ '.' for d in split(path, '/') if !isempty(d)) # replace with splitpath in Julia v1.1

function getsetup(experiment)
    fls = Dict{String, String}()
    for fl in split(experiment, ' ')
        f, l = split(fl, '#')
        fls[f] = l
    end
    fls
end

getnextrun(dir) = string(length(absfolders(dir)) + 1)

isnothidden(x) = x[1] ≠ '.'
isgooddir(root, x) = isdir(joinpath(root, x)) && isnothidden(x)
isgoodfile(root, x) = isfile(joinpath(root, x)) && isnothidden(x)

function getfl(dir, fl₀)
    fl = copy(fl₀)
    x = readdlm(joinpath(dir, "factors.csv"), ',', String)
    for i in 1:size(x, 1)
        fl[x[i,1]] = x[i,2]
    end
    fl
end

function getfiles(dir)
    files = String[]
    for file in readdir(dir)
        if isgoodfile(dir, file) && file ≠ "factors.csv"
            push!(files, file)
        end
    end
    files
end

function copy2local(path, datadir)
    for experiment in readdir(path)
        if isgooddir(path, experiment)
            FL = getsetup(experiment)
            pathexp = joinpath(path, experiment)
            for r in readdir(pathexp)
                if isgooddir(pathexp, r)
                    pathexpr = joinpath(pathexp, r)
                    fl = getfl(pathexpr, FL)
                    files = getfiles(pathexpr)
                    nextrun = getnextrun(datadir)
                    mkdir(joinpath(datadir, nextrun))
                    writedlm(joinpath(datadir, nextrun, "factors.csv"), fl, ',')
                    for file in files
                        cp(joinpath(pathexpr, file), joinpath(datadir, nextrun, file), force = true)
                        @info "Copied $file"
                    end
                end
            end
        end
    end
end

function getdata()
    datadir = tempname()
    while isdir(datadir)
        datadir = tempname()
    end
    mkdir(datadir)
    mktempdir() do path
        gdfuse_config = joinpath(@__DIR__, "gdfuse_config")
        run(`google-drive-ocamlfuse -config $gdfuse_config $path`)
        try
            copy2local(path, datadir)
        catch
            @warn "first pass crashed, trying one more time…"
            copy2local(path, datadir)
        end
        run(`fusermount -u $path`)
        run(`google-drive-ocamlfuse -cc`)
    end
    datadir
end

end # module
