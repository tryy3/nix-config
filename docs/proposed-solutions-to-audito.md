I'd like to start making some of the changes we found in @fw-16-audit-recommendations.
Below I have added a few comments on each note, not all tasks will need to be resolved, these have comments which ones we could skip.

What I want you to do is create a new plan referencing this document and create todos on each task so that we can keep track of progress. Place this document in @docs and once we feel the plan is looking good we'll start going through the tasks and fix them.

Sort them by simple->advanced so that we can tick off as many as possible from the start and then handle the more advanced/complex that might require a bit more hands on to fix.
So things like dead config, typos and such will be first.

Like always, remember that we have relevant skills regarding NixOS and best practices, so make sure you look for those first.

Proposed solutions to @fw-16-audito-recommendations

1. We should add some sort of configuration for where the "nix config" folder lives on a per-host/user setup to solve this type of situations.
   Going forwards I will probably have the nix-config live in $HOME/src/nix/nix-config, but on my WSL machine it currently lives in $HOME/nix-config. I will migrate this eventually but for now I have 2 machines with different paths.
   So what I am thinking is that we can override this somehow when needed.

2. We can try and disable this to see if it has any effect on existing setup
3. I think we can be more explicit here

4. I think the current setup is good enoguh, I know the risks but don't want to change this at the time
5. I'd like to stay on linux 7 now that it has been released, but I agree that we can move away from linuxPackages_latest. So a good compromise can be linuxPackages_7_0

6. We can enable this, I belive my ISP don't fully support IPV6 so unsure if I can use it properly, but I don't see the reason to keep it disabled

7. We can remove the ssh-agent from HM
8. We can disable the system wide zsh
9. Sure lets change this to use variables
10. I'd like to keep hostname1 as a template and iso for future usage, but I agree that we can do explicit host using whitelist
    11-12) Keep these for now, I think I want to do a cleanup after this
11. Go ahead with this changes
12. Fix this
13. Similarly to 3 I am fine with hard coding this, but in this instance if there is a way to grab the correct gpu easier then do it otherwise keep it, it's a minor change so if it breaks it's fine and I can resolve it
14. remove it if it's dead
15. My assumption is that "oxConfig" refers to osConfig in this instance
16. Lets wait with this because I have other changes that I want to do with GIT
17. I belive this was needed on my WSL machine for some reason, but lets remove it from my FW if it's not to complicated, I am fine with this staying if it requires a bunch of changes
18. Lets keep this, they can be part of the cleanup in 11-12
