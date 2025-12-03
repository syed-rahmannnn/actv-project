import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/company_selection_provider.dart';
import '../models/company_model.dart';
import '../services/company_service.dart';

/// A dropdown widget that allows switching between companies
/// Can be placed in any screen's app bar or header
class CompanySwitcherWidget extends StatefulWidget {
  final String memberId;
  final Color? textColor;
  final Color? iconColor;
  final Color? dropdownColor;

  const CompanySwitcherWidget({
    Key? key,
    required this.memberId,
    this.textColor,
    this.iconColor,
    this.dropdownColor,
  }) : super(key: key);

  @override
  State<CompanySwitcherWidget> createState() => _CompanySwitcherWidgetState();
}

class _CompanySwitcherWidgetState extends State<CompanySwitcherWidget> {
  List<Company> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    if (widget.memberId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final companies = await CompanyService.getCompanies(widget.memberId);

      if (!mounted) return;

      setState(() {
        _companies = companies;
        _isLoading = false;
      });

      // Set first company as active if none is set
      if (companies.isNotEmpty && mounted) {
        final companyProvider = context.read<CompanySelectionProvider>();
        if (companyProvider.activeCompany == null) {
          companyProvider.setActiveCompany(companies[0]);
        }
      }
    } catch (e) {
      print('❌ Error loading companies: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompanySelectionProvider>(
      builder: (context, companyProvider, child) {
        if (_isLoading) {
          return SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.textColor ?? Colors.white,
              ),
            ),
          );
        }

        if (_companies.isEmpty) {
          return Text(
            'No Companies',
            style: TextStyle(
              fontSize: 14,
              color: widget.textColor ?? Colors.black87,
            ),
          );
        }

        final activeCompany = companyProvider.activeCompany ?? _companies[0];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.dropdownColor ?? Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: activeCompany.id,
              icon: Icon(
                Icons.arrow_drop_down,
                color: widget.iconColor ?? Colors.white,
              ),
              dropdownColor: widget.dropdownColor ?? Colors.white,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.textColor ?? Colors.white,
              ),
              items: _companies.map((company) {
                return DropdownMenuItem<String>(
                  value: company.id,
                  child: Row(
                    children: [
                      if (company.logoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            company.logoUrl!,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 24,
                                height: 24,
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.business,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          company.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.dropdownColor != null
                                ? Colors.black87
                                : widget.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newCompanyId) {
                if (newCompanyId != null) {
                  final selectedCompany = _companies.firstWhere(
                    (c) => c.id == newCompanyId,
                  );
                  companyProvider.setActiveCompany(selectedCompany);
                  print('🔄 Company switched to: ${selectedCompany.name}');
                }
              },
            ),
          ),
        );
      },
    );
  }
}

/// A simple text button version of company switcher
class CompanySwitcherButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const CompanySwitcherButton({
    Key? key,
    required this.onTap,
    this.textColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CompanySelectionProvider>(
      builder: (context, companyProvider, child) {
        final activeCompany = companyProvider.activeCompany;

        if (activeCompany == null) {
          return TextButton.icon(
            onPressed: onTap,
            icon: Icon(Icons.business, color: iconColor ?? Colors.white),
            label: Text(
              'Select Company',
              style: TextStyle(color: textColor ?? Colors.white),
            ),
          );
        }

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (activeCompany.logoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      activeCompany.logoUrl!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.business,
                          size: 20,
                          color: iconColor ?? Colors.white,
                        );
                      },
                    ),
                  )
                else
                  Icon(
                    Icons.business,
                    size: 20,
                    color: iconColor ?? Colors.white,
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    activeCompany.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: iconColor ?? Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}
