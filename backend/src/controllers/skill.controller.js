import skillService from '../services/skill.service.js';

export class SkillController {
    /**
     * GET /api/skills
     */
    async getAllSkills(req, res, next) {
        try {
            const skills = await skillService.getAllSkills();
            res.json({
                success: true,
                data: skills
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/skills/:name
     */
    async getSkillByName(req, res, next) {
        try {
            const skill = await skillService.getSkillByName(req.params.name);
            res.json({
                success: true,
                data: skill
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/skills/initialize
     */
    async initializeSkills(req, res, next) {
        try {
            const skills = await skillService.initializeSkills();
            res.json({
                success: true,
                data: skills,
                message: 'Skills initialized successfully'
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/perks
     */
    async getAllPerks(req, res, next) {
        try {
            const perks = await skillService.getAllPerks();
            res.json({
                success: true,
                data: perks
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/perks/unlocked
     */
    async getUnlockedPerks(req, res, next) {
        try {
            const perks = await skillService.getUnlockedPerks();
            res.json({
                success: true,
                data: perks
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/perks/skill/:skillName
     */
    async getPerksBySkill(req, res, next) {
        try {
            const perks = await skillService.getPerksBySkill(req.params.skillName);
            res.json({
                success: true,
                data: perks
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * POST /api/perks/initialize
     */
    async initializePerks(req, res, next) {
        try {
            const perks = await skillService.initializePerks();
            res.json({
                success: true,
                data: perks,
                message: 'Perks initialized successfully'
            });
        } catch (error) {
            next(error);
        }
    }
}

export default new SkillController();
